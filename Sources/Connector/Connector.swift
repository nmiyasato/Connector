import Combine
import Foundation

/// @mockable
public protocol Connector {
    associatedtype EndpointType: Endpoint
    var dataProvider: DataProvider { get }
    func fetch(from endpoint: EndpointType) async throws -> EndpointType.Response
}

public extension Connector {
    func fetch(from endpoint: EndpointType) async throws -> EndpointType.Response where EndpointType.Response: Decodable {
        return try await dataProvider.fetch(from: endpoint)
    }
}
