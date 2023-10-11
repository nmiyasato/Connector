import Foundation

public protocol Endpoint {
    associatedtype Response: Decodable
    
    var baseURL: URL { get }
    var path: String? { get }
    var httpMethod: HTTPMethod? { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}
