import Foundation

public protocol DataProvider {
    var retryPolicy: RetryPolicy? { get }
    func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T
}

extension DataProvider {
    public func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T {
        let retryPolicy = retryPolicy ?? DefaultRetryPolicy()
        
        for attempt in 0..<retryPolicy.maxRetryAttempts {
            do {
                var urlRequest = URLRequest(url: endpoint.endpointURL)
                urlRequest.httpMethod = endpoint.httpMethod?.rawValue
                urlRequest.allHTTPHeaderFields = endpoint.headers

                let (data, response) = try await URLSession.shared.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }

                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse

            } catch {
                if attempt == retryPolicy.maxRetryAttempts - 1 {
                    throw error
                }
                try? await Task.sleep(nanoseconds: UInt64(retryPolicy.delay(forAttempt: attempt) * 1_000_000_000))
            }
        }
        throw URLError(.unknown)
    }
}
