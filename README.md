# Connector Package

The Connector package provides a robust networking layer designed to simplify the process of making network requests and handling responses in your Swift applications. It abstracts networking into reusable connectors that can be configured with different data providers, making it easier to switch between mock and live network services.

## Features

- **Generic Connectors**: Define your endpoints and let the Connector handle the rest.
- **Protocol-Oriented**: Easily mock your network layer for testing.
- **Asynchronous API**: Modern Swift async/await support.
- **Flexible Error Handling**: Customizable error responses for fine-grained control.
- **Retrying Mechanism**: Customizable retry logic to handle transient network issues.

## Installation

To include the Connector package in your project, add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/Connector.git", from: "1.0.0")
]
```

## Usage

Below are examples demonstrating the main structures of the Connector package:

### Defining an Endpoint

Create endpoints by conforming to the `Endpoint` protocol:

```swift
struct UserEndpoint: Endpoint {
    typealias Response = User

    var endpointURL: URL { URL(string: "https://api.example.com/user")! }
    // Other properties like HTTP method, headers, parameters...
}
```

### Implementing a Connector

Conform to the `Connector` protocol to implement a connector:

```swift
class LoginConnector: Connector {
    typealias EndpointType = UserEndpoint
    var dataProvider: DataProvider

    init(dataProvider: DataProvider = MockLoginService()) {
        self.dataProvider = dataProvider
    }

    func user(id: String, password: String) async -> Result<User, Error> {
        let endpoint = UserEndpoint(id: id, password: password)
        return await fetch(from: endpoint)
    }
}
```

### Using a DataProvider

Implement a data provider to handle the actual network or mock requests:

```swift
struct MockLoginService: DataProvider {
    func fetch<T: Decodable>(from endpoint: any Endpoint) async -> Result<T, Error> {
        // Mock fetching logic
    }
}
```

### Working with the Connector in ViewModels

```swift
class UserViewModel {
    var loginConnector: LoginConnector

    @Published var user: User?

    func getUser() async {
        let result = await loginConnector.user(id: "123", password: "secret")

        switch result {
        case .success(let fetchedUser):
            self.user = fetchedUser
        case .failure(let error):
            print("Error fetching user: \(error)")
        }
    }
}
```

### Mocking for Tests

```swift
func testUserFetching() async {
    let mockService = MockLoginService() // Returns a successful user fetch
    let connector = LoginConnector(dataProvider: mockService)

    let result = await connector.user(id: "test", password: "test")

    switch result {
    case .success(let user):
        XCTAssertEqual(user.id, "expected-id")
    case .failure(let error):
        XCTFail("Fetching user failed: \(error)")
    }
}
```

## Customization

- **Mock Responses**: Inject `MockLoginService` to return various responses for testing.
- **Error Handling**: Customize `MockLoginService` to return different error types based on the scenario.
- **Retry Logic**: Implement a retry strategy by conforming to a `RetryPolicy` protocol.
