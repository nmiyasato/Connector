import Foundation

public protocol DataProvider {
    func request<T: Decodable>(_ endpoint: any Endpoint) async -> Result<T, Error>
}
