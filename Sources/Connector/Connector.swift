import Combine
import Foundation

public protocol Connector {
    associatedtype EndpointType: Endpoint
    var dataProvider: DataProvider { get }
    func request(_ endpoint: EndpointType) async -> Result<EndpointType.Response, Error>
}

public extension Connector {
    func request(_ endpoint: EndpointType) async -> Result<EndpointType.Response, Error> where EndpointType.Response: Decodable {
        return await dataProvider.request(endpoint)
    }

}
