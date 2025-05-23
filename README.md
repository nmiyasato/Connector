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
    
    // Default implementation from DataProvider protocol will handle the actual networking
}

// For testing, create a mock service:
class MockAPIService: DataProvider {
    var retryPolicy: RetryPolicy? = nil
    
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
    
    func fetch<T: Decodable>(from endpoint: any Endpoint) async -> Result<T, Error> {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        switch endpoint {
        case let userEndpoint as UserEndpoint:
            if let user = mockUsers[userEndpoint.userId] as? T {
                return .success(user)
            }
            
        case _ as ProductEndpoint:
            if let products = mockProducts as? T {
                return .success(products)
            }
            
        default:
            break
        }
        
        return .failure(NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"]))
    }
}
```

### 4. Create a Unified Connector for Multiple Endpoints

```swift
class AppConnector {
    // Individual connectors for different endpoint types
    private let userConnector: UserConnector
    private let productConnector: ProductConnector
    
    init(apiToken: String, dataProvider: DataProvider = APIService()) {
        self.userConnector = UserConnector(apiToken: apiToken, dataProvider: dataProvider)
        self.productConnector = ProductConnector(apiToken: apiToken, dataProvider: dataProvider)
    }
    
    // User operations
    func getUser(id: String) async -> Result<User, Error> {
        return await userConnector.getUser(id: id)
    }
    
    // Product operations
    func getProducts(category: String? = nil, limit: Int = 20) async -> Result<[Product], Error> {
        return await productConnector.getProducts(category: category, limit: limit)
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
    
    func getUser(id: String) async -> Result<User, Error> {
        let endpoint = UserEndpoint(userId: id, apiToken: apiToken)
        return await fetch(from: endpoint)
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
    
    func getProducts(category: String? = nil, limit: Int = 20) async -> Result<[Product], Error> {
        let endpoint = ProductEndpoint(category: category, limit: limit, apiToken: apiToken)
        return await fetch(from: endpoint)
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
        
        let result = await connector.getProducts(category: category)
        
        DispatchQueue.main.async {
            self.isLoading = false
            
            switch result {
            case .success(let fetchedProducts):
                self.products = fetchedProducts
                self.error = nil
            case .failure(let fetchError):
                self.error = fetchError
            }
        }
    }
}
```

### 6. Set Up in Your App

```swift
// In your AppDelegate or main app setup
let apiToken = "your_api_token_here"

// For production
let apiService = APIService()
let appConnector = AppConnector(apiToken: apiToken, dataProvider: apiService)

// For testing or previews
let mockService = MockAPIService()
let mockConnector = AppConnector(apiToken: "mock_token", dataProvider: mockService)

// Create and use your ViewModels
let productViewModel = ProductViewModel(connector: appConnector)

// Use the ViewModels in your views
Task {
    await productViewModel.loadProducts(category: "electronics")
}
```

### 7. Testing

```swift
class ConnectorTests: XCTestCase {
    func testProductFetching() async {
        let mockService = MockAPIService()
        let connector = AppConnector(apiToken: "test_token", dataProvider: mockService)
        
        let result = await connector.getProducts(category: "electronics")
        
        switch result {
        case .success(let products):
            XCTAssertEqual(products.count, 2)
            XCTAssertEqual(products[0].name, "iPhone")
        case .failure(let error):
            XCTFail("Product fetching failed: \(error)")
        }
    }
}
```

## Customization

- **Mock Responses**: Inject custom data providers to return various responses for testing.
- **Error Handling**: Customize your data provider to return different error types based on the scenario.
- **Retry Logic**: Implement a retry strategy by conforming to the `RetryPolicy` protocol.
