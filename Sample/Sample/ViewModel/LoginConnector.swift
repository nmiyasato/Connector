import Foundation
import Connector

class LoginConnector: Connector {
    typealias EndpointType = UserEndpoint
    var dataProvider: DataProvider

    init(dataProvider: DataProvider = MockLoginService()) {
        self.dataProvider = dataProvider
    }

    func user(id: String, password: String) async throws -> User {
        let endpoint = UserEndpoint(endpointURL: URL(string: "https://www.google.com")!, id: id, password: password)
        return try await dataProvider.fetch(from: endpoint)
    }
}

struct MockLoginService: DataProvider {
    var taskManager: TaskManager = TaskManager()
    
    var retryPolicy: RetryPolicy? { nil }

    func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T {
        guard endpoint is UserEndpoint else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Endpoint type mismatch"])
        }

        let mockUserData = """
        {
            "username": "john_doe",
            "email": "john@example.com"
        }
        """.data(using: .utf8)!

        return try JSONDecoder().decode(T.self, from: mockUserData)
    }
}
