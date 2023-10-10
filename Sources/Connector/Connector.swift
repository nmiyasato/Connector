import Combine
import Foundation

public protocol Connector {
    associatedtype EndpointType: Endpoint
    var dataProvider: DataProvider { get }
    func fetch(from endpoint: EndpointType) async -> Result<EndpointType.Response, Error>
}

public extension Connector {
    func fetch(from endpoint: EndpointType) async -> Result<EndpointType.Response, Error> where EndpointType.Response: Decodable {
        return await dataProvider.request(endpoint)
    }

}
