import XCTest
@testable import Connector


final class ConnectorTests: XCTestCase {
    
    struct EndpointMock: Endpoint {
        typealias Response = String
        var endpointURL: URL
        var httpMethod: HTTPMethod? = .get
        var headers: [String: String]? = nil
        var parameters: [String: Any]? = nil
    }

    struct MockConnector: Connector {
        typealias EndpointType = EndpointMock
        var dataProvider: DataProvider
    }

    func testFetch_ForwardsCallToDataProvider() async throws {
        // Arrange
        let mockDataProvider = DataProviderMock()
        let mockEndpoint = EndpointMock(endpointURL: URL(string: "https://example.com")!)
        var fetchCalled = false
        
        mockDataProvider.fetchHandler = { endpoint in
            XCTAssertEqual(endpoint.endpointURL, mockEndpoint.endpointURL)
            fetchCalled = true
            return "Mock Response"
        }
        
        let connector = MockConnector(dataProvider: mockDataProvider)
        
        // Act
        let _ = try await connector.fetch(from: mockEndpoint)
        
        // Assert
        XCTAssertTrue(fetchCalled, "Fetch call was not forwarded to the DataProvider")
    }
}
