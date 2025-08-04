import Foundation

/// @mockable
public protocol DataProvider {
    var retryPolicy: RetryPolicy? { get }
    
    /// Fetches data from the specified endpoint
    /// - Parameter endpoint: The endpoint to fetch data from
    /// - Returns: Decoded response of type T
    /// - Throws: Error if the request fails
    func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T
    
    var taskManager: TaskManager { get }

    /// Cancels all ongoing requests
    func cancelAllRequests() async
    
    /// Cancels requests for a specific endpoint
    /// - Parameter endpoint: The endpoint for which to cancel requests
    func cancelRequest(for endpoint: any Endpoint) async
}

/// Default implementation for the DataProvider protocol
public extension DataProvider {
    
    func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T {
        let endpointId = "\(endpoint.endpointURL.host ?? "unknown"):\(endpoint.endpointURL.path)"
        let task = Task<T, Error> {
            
            let urlRequest = try createRequest(for: endpoint)
            let retryPolicy = self.retryPolicy ?? DefaultRetryPolicy()
            
            for attempt in 0..<retryPolicy.maxRetryAttempts {
                do {
                    try Task.checkCancellation()
                    
                    let (data, response) = try await URLSession.shared.data(for: urlRequest)
                    
                    try Task.checkCancellation()

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        throw HTTPError(statusCode: httpResponse.statusCode, data: data)
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
        let endpointId = "\(endpoint.endpointURL.host ?? "unknown"):\(endpoint.endpointURL.path)"
        await taskManager.cancelTasks(for: endpointId)
    }
    
    func cancelAllRequests() async {
        await taskManager.cancelAllTasks()
    }

    private func createRequest(for endpoint: any Endpoint) throws -> URLRequest {
        var urlRequest = URLRequest(url: endpoint.endpointURL)
        urlRequest.httpMethod = endpoint.httpMethod?.rawValue
        urlRequest.allHTTPHeaderFields = endpoint.headers
        
        if let parameters = endpoint.parameters,
           let httpMethod = endpoint.httpMethod,
           httpMethod != .get {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            urlRequest.httpBody = jsonData
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                urlRequest.httpBody = jsonData
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                let endpointId = "\(endpoint.endpointURL.host ?? "unknown"):\(endpoint.endpointURL.path)"
                throw DataProviderError.serializationFailed(endpoint: endpointId, parameters: parameters, underlyingError: error)
            }
        }
        
        return urlRequest
    }
}
