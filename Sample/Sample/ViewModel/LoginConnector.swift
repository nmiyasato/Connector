import Foundation
import Connector
class LoginConnector: Connector {
    typealias EndpointType = UserEndpoint
    var dataProvider: DataProvider

    init(dataProvider: DataProvider = MockLoginService()) {
        self.dataProvider = dataProvider
    }

    func user(id: String, password: String) async -> Result<User, Error> {
        let endpoint = UserEndpoint(baseURL: URL(string: "https://www.google.com")!, id: id, password: password)
        return await request(endpoint)
    }
}

struct MockLoginService: DataProvider {

    func request<T: Decodable>(_ endpoint: any Endpoint) async -> Result<T, Error> {

        // Ensure the endpoint is of the type we expect
        guard endpoint is UserEndpoint else {
            return .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Endpoint type mismatch"]))
        }

        // Return a mock user response
        let mockUserData = """
        {
            "username": "john_doe",
            "email": "john@example.com"
        }
        """.data(using: .utf8)!

        do {
            let mockedUser = try JSONDecoder().decode(T.self, from: mockUserData)
            return .success(mockedUser)
        } catch {
            return .failure(error)
        }
    }
}
