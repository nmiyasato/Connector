import Foundation

/// @mockable
public protocol Endpoint {
    associatedtype Response: Decodable
    
    var endpointURL: URL { get }
    var httpMethod: HTTPMethod? { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
}

extension Endpoint {
    public var hostURL: URL? {
        guard let host = endpointURL.host else { return nil }
        let scheme = endpointURL.scheme ?? "https"
        return URL(string: "\(scheme)://\(host)")
    }
    public var path: String { 
        endpointURL.path.isEmpty ? "/" : endpointURL.path
    }
}

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
