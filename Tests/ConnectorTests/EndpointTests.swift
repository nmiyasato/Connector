import XCTest
@testable import Connector

final class EndpointTests: XCTestCase {
    
    func testEndpointProperties() {
        // Given
        let url = URL(string: "https://api.example.com/path/to/resource")!
        let endpoint = TestEndpoint(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json", "Authorization": "Bearer token"],
            parameters: ["key1": "value1", "key2": 42]
        )
        
        // Then
        XCTAssertEqual(endpoint.endpointURL, url)
        XCTAssertEqual(endpoint.httpMethod, .post)
        XCTAssertEqual(endpoint.headers?["Content-Type"], "application/json")
        XCTAssertEqual(endpoint.headers?["Authorization"], "Bearer token")
        XCTAssertEqual(endpoint.parameters?["key1"] as? String, "value1")
        XCTAssertEqual(endpoint.parameters?["key2"] as? Int, 42)
    }
    
    func testEndpointExtensionProperties() {
        // Given
        let url = URL(string: "https://api.example.com/path/to/resource")!
        let endpoint = TestEndpoint(url: url)
        
        // Then
        XCTAssertEqual(endpoint.hostURL.absoluteString, "https://api.example.com")
        XCTAssertEqual(endpoint.path, "/path/to/resource")
    }
    
    func testHTTPMethodRawValues() {
        // Test that HTTP method enum values are correctly defined
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
    }
}