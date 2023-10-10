import Foundation
import Connector

struct User: Codable {
    let username: String
}

struct UserEndpoint: Endpoint {
    typealias Response = User
    var baseURL: URL
    var httpMethod: HTTPMethod { .get }
    var headers: [String : String]?
    var parameters: [String : Any]?

    let id: String
    let password: String

    var path: String {
        return "/user/\(id)"  // Assuming the API endpoint looks something like "/user/{id}"
    }

    // If you need request parameters, headers, body data, etc., you can add those properties/methods here.
}
