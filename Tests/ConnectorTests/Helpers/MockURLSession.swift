import Foundation
@testable import Connector

class MockURLSession {
    static var shared = MockURLSession()
    
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        
        guard let data = data, let response = response else {
            throw URLError(.unknown)
        }
        
        return (data, response)
    }
    
    func reset() {
        data = nil
        response = nil
        error = nil
    }
}

// Extension to replace URLSession.shared with our mock during tests
extension URLSession {
    static var mock: MockURLSession {
        return MockURLSession.shared
    }
}