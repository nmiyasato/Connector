import Foundation

public protocol DataProvider {
    var retryPolicy: RetryPolicy? { get }
    func fetch<T: Decodable>(from endpoint: any Endpoint) async -> Result<T, Error>
}

extension DataProvider {
    public func fetch<T: Decodable>(from endpoint: any Endpoint) async -> Result<T, Error> {
        var lastError: Error
        for attempt in 0..<retryPolicy.maxRetryAttempts {
            do {
                // Here you might want to customize your URLRequest based on the endpoint
                var urlRequest = URLRequest(url: endpoint.endpointURL)
                urlRequest.httpMethod = endpoint.httpMethod?.rawValue
                urlRequest.allHTTPHeaderFields = endpoint.headers

                let (data, response) = try await URLSession.shared.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return .success(decodedResponse)

            } catch {
                lastError = error
                if attempt == retryPolicy.maxRetryAttempts - 1 {
                    return .failure(error)
                }
                await Task.sleep(UInt64(retryPolicy.delay(forAttempt: attempt) * 1_000_000_000))
            }
        }
        return .failure(lastError)
    }
}
