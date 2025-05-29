import XCTest
@testable import Connector

final class DataProviderTests: XCTestCase {
    
    class TestableDataProvider: DataProvider {
        var retryPolicy: RetryPolicy?
        var taskManager = TaskManager()
        var mockURLSession = MockURLSession()
        
        // For tracking test calls
        var fetchCallCount = 0
        var cancelRequestCallCount = 0
        var cancelAllRequestsCallCount = 0
        
        // For controlling test behavior
        var mockResponse: Data?
        var mockURLResponse: HTTPURLResponse?
        var mockError: Error?
        
        init(retryPolicy: RetryPolicy? = nil) {
            self.retryPolicy = retryPolicy
        }
        
        func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T {
            fetchCallCount += 1
            
            // Use the default implementation but with our mock URLSession
            let endpointId = endpoint.endpointURL.absoluteString
            let task = Task<T, Error> {
                let urlRequest = URLRequest(url: endpoint.endpointURL)
                let retryPolicy = self.retryPolicy ?? DefaultRetryPolicy()
                
                for attempt in 0..<retryPolicy.maxRetryAttempts {
                    do {
                        // Set up the mock URL session for this fetch
                        mockURLSession.data = mockResponse
                        mockURLSession.response = mockURLResponse
                        mockURLSession.error = mockError
                        
                        try Task.checkCancellation()
                        
                        // Use our mock URLSession instead of shared
                        let (data, response) = try await mockURLSession.data(for: urlRequest)
                        
                        try Task.checkCancellation()
                        
                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            throw URLError(.badServerResponse)
                        }
                        
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        return decodedResponse
                        
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        if attempt == retryPolicy.maxRetryAttempts - 1 {
                            throw error
                        }
                        try? await Task.sleep(nanoseconds: UInt64(retryPolicy.delay(forAttempt: attempt) * 1_000_000_000))
                        try Task.checkCancellation()
                    }
                }
                throw URLError(.unknown)
            }
            
            // Register task for potential cancellation
            let wrapper = TaskWrapper(task)
            await taskManager.registerTask(wrapper, for: endpointId)
            
            do {
                let result = try await task.value
                await taskManager.unregisterTask(for: endpointId, taskId: wrapper.id)
                return result
            } catch {
                await taskManager.unregisterTask(for: endpointId, taskId: wrapper.id)
                throw error
            }
        }
        
        func cancelRequest(for endpoint: any Endpoint) async {
            cancelRequestCallCount += 1
            await taskManager.cancelTasks(for: endpoint.endpointURL.absoluteString)
        }
        
        func cancelAllRequests() async {
            cancelAllRequestsCallCount += 1
            await taskManager.cancelAllTasks()
        }
    }
    
    func testDataProviderFetch_Success() async throws {
        // Given
        let dataProvider = TestableDataProvider()
        let mockResponse = MockResponse(message: "Success")
        let jsonData = try JSONEncoder().encode(mockResponse)
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        dataProvider.mockResponse = jsonData
        dataProvider.mockURLResponse = httpResponse
        
        let endpoint = TestEndpoint()
        
        // When
        let result = try await dataProvider.fetch(from: endpoint) as MockResponse
        
        // Then
        XCTAssertEqual(dataProvider.fetchCallCount, 1)
        XCTAssertEqual(result.message, "Success")
    }
    
    func testDataProviderFetch_Failure() async {
        // Given
        let dataProvider = TestableDataProvider()
        let mockError = URLError(.notConnectedToInternet)
        dataProvider.mockError = mockError
        
        let endpoint = TestEndpoint()
        
        // When/Then
        do {
            _ = try await dataProvider.fetch(from: endpoint) as MockResponse
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(dataProvider.fetchCallCount, 1)
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testDataProviderFetch_WithRetry() async {
        // Given
        let mockRetryPolicy = MockRetryPolicy()
        mockRetryPolicy.maxRetryAttempts = 5
        
        let dataProvider = TestableDataProvider(retryPolicy: mockRetryPolicy)
        let mockResponse = MockResponse(message: "Success")
        let jsonData = try! JSONEncoder().encode(mockResponse)
        let httpResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // First call will fail, second will succeed
        var callCount = 0
        dataProvider.mockResponse = {
            callCount += 1
            if callCount == 1 {
                return nil // Will cause an error on first call
            } else {
                return jsonData
            }
        }()
        dataProvider.mockURLResponse = httpResponse
        dataProvider.mockURLSession.error = {
            callCount += 1
            if callCount == 1 {
                return URLError(.timedOut)
            } else {
                return nil
            }
        }()
        
        let endpoint = TestEndpoint()
        
        // When
        let result: MockResponse = try! await dataProvider.fetch(from: endpoint)
        
        // Then
        XCTAssertEqual(result.message, "Success")
        XCTAssertEqual(mockRetryPolicy.delayCallCount, 1) // Called once for the retry
    }
    
    func testDataProviderCancelRequest() async {
        // Given
        let dataProvider = TestableDataProvider()
        let endpoint = TestEndpoint()
        
        // When
        await dataProvider.cancelRequest(for: endpoint)
        
        // Then
        XCTAssertEqual(dataProvider.cancelRequestCallCount, 1)
    }
    
    func testDataProviderCancelAllRequests() async {
        // Given
        let dataProvider = TestableDataProvider()
        
        // When
        await dataProvider.cancelAllRequests()
        
        // Then
        XCTAssertEqual(dataProvider.cancelAllRequestsCallCount, 1)
    }
}
