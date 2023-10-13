import Foundation

public protocol Endpoint {
    associatedtype Response: Decodable
    
    var endpointURL: URL { get }
    var httpMethod: HTTPMethod? { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
}

extension Endpoint {
    public var hostURL: URL { URL(string: endpointURL.scheme ?? "https:" + "//" + (endpointURL.host ?? ""))! }
    public var path: String { endpointURL.pathComponents.joined(separator: "/").replacingOccurrences(of: "//", with: "/") }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}
