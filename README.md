# Networking Abstractions: Connector, DataProvider & Endpoint

Welcome to our Networking Abstraction layer, a sleek, powerful, and flexible set of protocols to manage your network operations seamlessly. With a keen focus on testability and separation of concerns, this framework is designed to simplify network calls, enhance code reusability, and improve the overall architecture of your network layer. Let's dive into its core components:

## Connector

The **Connector** is the forefront of this networking architecture. It ties everything together by managing how requests are fetched. By associating each connector with a particular type of endpoint, it maintains a clear relationship with the specific network operations required.

### Features:
- **Associated Endpoint Type**: Links the connector with a specific endpoint type to enforce consistency.
- **Fetching**: Manages the fetch operation, streamlining how data is retrieved and decoded.

## DataProvider

The **DataProvider** is where the actual network logic resides. It determines how data is fetched—whether from a network source, cache, or mock data source, making it extremely flexible and testable.

### Features:
- **Fetching with Generics**: Uses generics to decode the fetched data into the desired type seamlessly.
- **Error Handling**: Structured to manage various error types, allowing for comprehensive error handling.

## Endpoint

The **Endpoint** protocol delineates the essential data required to make a network request, such as the URL, HTTP method, headers, and parameters.

### Features:
- **Decodable Response**: Enables the decoding of responses into Swift types.
- **URL Composition**: Aids in creating comprehensive URLs including base URL and path components.
- **HTTP Method and Parameters**: Outlines the HTTP methods and parameters for each endpoint to maintain clarity.

## Getting Started

1. **Define Your Endpoints**: Create structs or classes conforming to the `Endpoint` protocol, specifying the necessary details.
2. **Create DataProviders**: Define your data providers conforming to the `DataProvider` protocol, specifying how data should be fetched.
3. **Implement Connectors**: Implement connectors to tie endpoints and data providers together, orchestrating the fetching process.

## Code Example

Here’s a quick example demonstrating the implementation of these protocols:

```swift
class LoginConnector: Connector {
    typealias EndpointType = UserEndpoint
    var dataProvider: DataProvider

    func user(id: String, password: String) async -> Result<User, Error> {
        let endpoint = UserEndpoint(...)
        return await fetch(from: endpoint)
    }
}

struct MockLoginService: DataProvider {
    func fetch<T: Decodable>(from endpoint: any Endpoint) async -> Result<T, Error> {
        // Your fetching logic goes here.
    }
}
```

## Conclusion

Harness the power of our Networking Abstractions to make your network layer more manageable, testable, and elegant. Adapt each component to your specific needs and unlock a world of flexible networking possibilities.
