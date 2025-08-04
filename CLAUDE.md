# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Connector is a Swift Package Manager (SPM) based networking library that provides a protocol-oriented networking layer for Swift applications. It uses modern Swift concurrency (async/await) with actor-based task management and supports iOS 17+, macOS 10.15+.

## Essential Commands

### Building & Testing
```bash
# Build the package
swift build

# Run all tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# Clean build artifacts
swift package clean
```

### Mock Generation
```bash
# Generate mocks using Mockolo (required after protocol changes)
./generate_mocks.sh
```

### Package Management
```bash
# Update dependencies
swift package update

# Generate Xcode project (if needed)
swift package generate-xcodeproj
```

## Architecture Overview

The library follows a protocol-oriented design with these core components:

- **Endpoint Protocol**: Defines API endpoints with URL, HTTP method, headers, and parameters
- **Connector Protocol**: Generic protocol for making network requests, parameterized by endpoint type
- **DataProvider Protocol**: Handles actual network operations with retry logic and error handling
- **TaskManager Actor**: Thread-safe request tracking and cancellation management
- **RetryPolicy Protocol**: Configurable retry behavior with exponential backoff

### Key Implementation Files
- `Sources/Connector/Connector.swift` - Core connector protocol and implementation
- `Sources/Connector/DataProvider.swift` - Network operation abstraction
- `Sources/Connector/TaskManager.swift` - Actor-based request lifecycle management
- `Sources/Connector/StandardDataProvider.swift` - Default implementation with retry logic

## Testing Architecture

- All protocols marked with `/// @mockable` for Mockolo code generation
- Generated mocks in `Tests/ConnectorTests/Mocks/GeneratedMocks.swift`
- Test helpers in `Tests/ConnectorTests/Helpers/` for common test scenarios
- Mock generation script `generate_mocks.sh` must be run after protocol changes

## Key Patterns

### Generic Design
- Endpoints use associated types for type-safe responses
- Connectors are generic over their endpoint types: `Connector<EndpointType>`
- All network responses are validated against expected types at compile time

### Concurrency & Cancellation
- Uses modern Swift async/await throughout
- TaskManager actor handles request cancellation (individual or bulk)
- Cooperative cancellation via CancellationError support

### Error Handling
- HTTP status codes 200-299 considered successful
- Comprehensive retry logic with configurable policies
- Custom error types for network failures and cancellation

## Development Notes

- Minimum Swift 5.9 required (uses Swift 6.1.2)
- Package.swift defines platform minimums and dependencies
- Sample iOS app in `Sample/` demonstrates complete integration
- TestPlan.xctestplan configures Xcode test execution
- No external dependencies beyond system frameworks