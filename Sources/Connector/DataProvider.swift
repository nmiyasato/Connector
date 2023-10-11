import Foundation

public protocol DataProvider {
    func fetch<T: Decodable>(from endpoint: any Endpoint) async -> Result<T, Error>
}
