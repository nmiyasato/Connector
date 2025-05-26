# Connector Package

The Connector package provides a robust networking layer designed to simplify the process of making network requests and handling responses in your Swift applications. It abstracts networking into reusable connectors that can be configured with different data providers, making it easier to switch between mock and live network services.

## Features

- **Generic Connectors**: Define your endpoints and let the Connector handle the rest.
- **Protocol-Oriented**: Easily mock your network layer for testing.
- **Asynchronous API**: Modern Swift async/await support.
- **Flexible Error Handling**: Customizable error responses for fine-grained control.
- **Retrying Mechanism**: Customizable retry logic to handle transient network issues.
- **Task Management**: Built-in support for managing and cancelling network requests.

## Installation

To include the Connector package in your project, add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nmiyasato/Connector.git", from: "1.0.0")
]
```

Or in Xcode, go to File > Swift Packages > Add Package Dependency and enter the repository URL.

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
    
    init(dataProvider: DataProvider = StandardDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    func user(id: String, password: String) async throws -> User {
        let endpoint = UserEndpoint(id: id, password: password)
        return try await fetch(from: endpoint)
    }
}
```

### Using a DataProvider

Implement a data provider to handle the actual network or mock requests:

```swift
class MockLoginService: DataProvider {
    var retryPolicy: RetryPolicy? = nil
    let taskManager = TaskManager()
    
    func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T {
        // Mock fetching logic
        // Return decoded data or throw an error
        throw URLError(.badServerResponse)
    }
}
```

You can also use the built-in `StandardDataProvider` class:

```swift
let dataProvider = StandardDataProvider(retryPolicy: DefaultRetryPolicy())
```

### Working with the Connector in ViewModels

```swift
class UserViewModel {
    var loginConnector: LoginConnector
    
    @Published var user: User?
    @Published var error: Error?
    
    func getUser() async {
        do {
            let fetchedUser = try await loginConnector.user(id: "123", password: "secret")
            self.user = fetchedUser
        } catch {
            self.error = error
            print("Error fetching user: \(error)")
        }
    }
    
    func cancelRequests() async {
        await loginConnector.dataProvider.cancelAllRequests()
    }
}
```

### Mocking for Tests

```swift
func testUserFetching() async throws {
    let mockService = MockLoginService() // Returns a successful user fetch
    let connector = LoginConnector(dataProvider: mockService)
    
    do {
        let user = try await connector.user(id: "test", password: "test")
        XCTAssertEqual(user.id, "expected-id")
    } catch {
        XCTFail("Fetching user failed: \(error)")
    }
}
```


## Complete Example: Project with Multiple Endpoints

This section demonstrates how to use the Connector package in a project with multiple API endpoints.

### 1. Define Your Data Models

First, create model structures for each type of data you need to fetch:

```swift
// User model
struct User: Codable {
    let id: String
    let username: String
    let email: String
}

// Product model
struct Product: Codable {
    let id: String
    let name: String
    let price: Double
    let description: String
}

// Order model
struct Order: Codable {
    let id: String
    let userId: String
    let products: [Product]
    let totalAmount: Double
    let date: Date
}
```

### 2. Define Your Endpoints

Create endpoint types for each API endpoint you need to access:

```swift
// User endpoint
struct UserEndpoint: Endpoint {
    typealias Response = User
    
    let userId: String
    
    var endpointURL: URL { 
        URL(string: "https://api.example.com/users/\(userId)")! 
    }
    var httpMethod: HTTPMethod? { .get }
    var headers: [String: String]? { 
        ["Authorization": "******"] 
    }
    var parameters: [String: Any]? { nil }
    
    private let apiToken: String
    
    init(userId: String, apiToken: String) {
        self.userId = userId
        self.apiToken = apiToken
    }
}

// Product endpoint
struct ProductEndpoint: Endpoint {
    typealias Response = [Product]
    
    var endpointURL: URL { 
        URL(string: "https://api.example.com/products\(queryString)")! 
    }
    var httpMethod: HTTPMethod? { .get }
    var headers: [String: String]? { 
        ["Authorization": "******"] 
    }
    var parameters: [String: Any]? { nil }
    
    private let category: String?
    private let limit: Int
    private let apiToken: String
    
    private var queryString: String {
        var components: [String] = []
        if let category = category {
            components.append("category=\(category)")
        }
        components.append("limit=\(limit)")
        return components.isEmpty ? "" : "?" + components.joined(separator: "&")
    }
    
    init(category: String? = nil, limit: Int = 20, apiToken: String) {
        self.category = category
        self.limit = limit
        self.apiToken = apiToken
    }
}
```


### 3. Implement Your API Service

Create a `DataProvider` that handles actual network requests:

```swift
class APIService: DataProvider {
    var retryPolicy: RetryPolicy? = DefaultRetryPolicy()
    let taskManager = TaskManager()
    
    // Default implementation from DataProvider protocol will handle the actual networking
}

// For testing, create a mock service:
class MockAPIService: DataProvider {
    var retryPolicy: RetryPolicy? = nil
    let taskManager = TaskManager()
    
    // Mock data for testing
    let mockUsers: [String: User] = [
        "123": User(id: "123", username: "johndoe", email: "john@example.com")
    ]
    
    let mockProducts: [Product] = [
        Product(id: "1", name: "iPhone", price: 999.0, description: "Smartphone"),
        Product(id: "2", name: "MacBook", price: 1999.0, description: "Laptop")
    ]
    
    let mockOrders: [String: Order] = [
        "order1": Order(
            id: "order1", 
            userId: "123", 
            products: [
                Product(id: "1", name: "iPhone", price: 999.0, description: "Smartphone")
            ],
            totalAmount: 999.0,
            date: Date()
        )
    ]
    
    func fetch<T: Decodable>(from endpoint: any Endpoint) async throws -> T {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        switch endpoint {
        case let userEndpoint as UserEndpoint:
            if let user = mockUsers[userEndpoint.userId] as? T {
                return user
            }
            
        case _ as ProductEndpoint:
            if let products = mockProducts as? T {
                return products
            }
            
        default:
            break
        }
        
        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
    }
}
```

### 4. Create a Unified Connector for Multiple Endpoints

```swift
class AppConnector {
    // Individual connectors for different endpoint types
    private let userConnector: UserConnector
    private let productConnector: ProductConnector
    
    init(apiToken: String, dataProvider: DataProvider = StandardDataProvider()) {
        self.userConnector = UserConnector(apiToken: apiToken, dataProvider: dataProvider)
        self.productConnector = ProductConnector(apiToken: apiToken, dataProvider: dataProvider)
    }
    
    // User operations
    func getUser(id: String) async throws -> User {
        return try await userConnector.getUser(id: id)
    }
    
    // Product operations
    func getProducts(category: String? = nil, limit: Int = 20) async throws -> [Product] {
        return try await productConnector.getProducts(category: category, limit: limit)
    }
    
    // Cancellation methods
    func cancelAllRequests() async {
        await userConnector.dataProvider.cancelAllRequests()
    }
    
    func cancelUserRequests(id: String) async {
        let endpoint = UserEndpoint(userId: id, apiToken: "")
        await userConnector.dataProvider.cancelRequest(for: endpoint)
    }
}

// Individual connector implementations
class UserConnector: Connector {
    typealias EndpointType = UserEndpoint
    var dataProvider: DataProvider
    private let apiToken: String
    
    init(apiToken: String, dataProvider: DataProvider) {
        self.apiToken = apiToken
        self.dataProvider = dataProvider
    }
    
    func getUser(id: String) async throws -> User {
        let endpoint = UserEndpoint(userId: id, apiToken: apiToken)
        return try await fetch(from: endpoint)
    }
}

class ProductConnector: Connector {
    typealias EndpointType = ProductEndpoint
    var dataProvider: DataProvider
    private let apiToken: String
    
    init(apiToken: String, dataProvider: DataProvider) {
        self.apiToken = apiToken
        self.dataProvider = dataProvider
    }
    
    func getProducts(category: String? = nil, limit: Int = 20) async throws -> [Product] {
        let endpoint = ProductEndpoint(category: category, limit: limit, apiToken: apiToken)
        return try await fetch(from: endpoint)
    }
}
```


### 5. Use in ViewModels

```swift
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let connector: AppConnector
    
    init(connector: AppConnector) {
        self.connector = connector
    }
    
    func loadProducts(category: String? = nil) async {
        isLoading = true
        
        do {
            let fetchedProducts = try await connector.getProducts(category: category)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.products = fetchedProducts
                self.error = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.error = error
            }
        }
    }
    
    func cancelAllRequests() async {
        await connector.cancelAllRequests()
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}
```

### 6. Set Up in Your App

```swift
// In your AppDelegate or main app setup
let apiToken = "your_api_token_here"

// For production with default retry policy
let apiService = StandardDataProvider(retryPolicy: DefaultRetryPolicy())
let appConnector = AppConnector(apiToken: apiToken, dataProvider: apiService)

// For production with custom retry policy
let customRetryPolicy = CustomRetryPolicy()
let customApiService = StandardDataProvider(retryPolicy: customRetryPolicy)
let customAppConnector = AppConnector(apiToken: apiToken, dataProvider: customApiService)

// For testing or previews
let mockService = MockAPIService()
let mockConnector = AppConnector(apiToken: "mock_token", dataProvider: mockService)

// Create and use your ViewModels
let productViewModel = ProductViewModel(connector: appConnector)

// Use the ViewModels in your views
Task {
    await productViewModel.loadProducts(category: "electronics")
    
    // Cancel the request if needed
    // await productViewModel.cancelAllRequests()
}
```

### 7. Testing

```swift
class ConnectorTests: XCTestCase {
    func testProductFetching() async throws {
        let mockService = MockAPIService()
        let connector = AppConnector(apiToken: "test_token", dataProvider: mockService)
        
        do {
            let products = try await connector.getProducts(category: "electronics")
            XCTAssertEqual(products.count, 2)
            XCTAssertEqual(products[0].name, "iPhone")
        } catch {
            XCTFail("Product fetching failed: \(error)")
        }
    }
    
    func testCancellation() async {
        let mockService = MockAPIService()
        let connector = AppConnector(apiToken: "test_token", dataProvider: mockService)
        
        // Start a request
        Task {
            do {
                _ = try await connector.getProducts()
                XCTFail("Request should have been cancelled")
            } catch is CancellationError {
                // Expected behavior when cancelled
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        // Cancel the request
        await connector.cancelAllRequests()
        
        // Verify cancellation (could check TaskManager state if exposed)
    }
}
```
```

## Customization

- **Mock Responses**: Inject custom data providers to return various responses for testing.
- **Error Handling**: Customize your data provider to handle different error types based on the scenario.
- **Retry Logic**: Implement a retry strategy by conforming to the `RetryPolicy` protocol.
- **Task Management**: Use the `TaskManager` to track, manage, and cancel ongoing network requests.
- **Request Cancellation**: Cancel specific requests or all requests using the methods provided by `DataProvider`.

### Custom Retry Policy Example

```swift
struct CustomRetryPolicy: RetryPolicy {
    var maxRetryAttempts: Int = 5
    
    func delay(forAttempt attempt: Int) -> TimeInterval {
        // Exponential backoff with jitter
        let baseDelay = 1.0
        let maxDelay = 30.0
        let exponentialDelay = min(maxDelay, baseDelay * pow(2.0, Double(attempt)))
        let jitter = Double.random(in: 0.0...0.3) * exponentialDelay
        return exponentialDelay + jitter
    }
}
```

## Task Cancellation

The Connector package provides built-in support for cancelling network requests through the `TaskManager` actor, which is accessible via any `DataProvider` instance.

### Cancelling All Requests

```swift
let connector = AppConnector(apiToken: "your_token", dataProvider: StandardDataProvider())

// Cancel all ongoing requests
await connector.dataProvider.cancelAllRequests()
```

### Cancelling Specific Requests

```swift
let endpoint = UserEndpoint(userId: "123", apiToken: "your_token")
await connector.dataProvider.cancelRequest(for: endpoint)
```

### Handling Cancellation in Client Code

```swift
do {
    let products = try await connector.getProducts()
    // Process products
} catch is CancellationError {
    // Handle cancellation specifically
    print("Request was cancelled")
} catch {
    // Handle other errors
    print("Request failed: \(error)")
}
```
