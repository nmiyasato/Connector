import Foundation
@testable import Connector

struct MockResponse: Codable {
    let message: String
}

struct TestEndpoint: Endpoint {
    typealias Response = MockResponse
    
    var endpointURL: URL
    var httpMethod: HTTPMethod?
    var headers: [String: String]?
    var parameters: [String: Any]?
    
    init(
        url: URL = URL(string: "https://example.com/test")!,
        method: HTTPMethod? = .get,
        headers: [String: String]? = ["Content-Type": "application/json"],
        parameters: [String: Any]? = ["key": "value"]
    ) {
        self.endpointURL = url
        self.httpMethod = method
        self.headers = headers
        self.parameters = parameters
    }
}
