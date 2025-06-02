import XCTest
@testable import Connector

final class RetryPolicyTests: XCTestCase {
    
    func testDefaultRetryPolicy() {
        // Given
        let retryPolicy = DefaultRetryPolicy()
        
        // Then
        XCTAssertEqual(retryPolicy.maxRetryAttempts, 3)
        XCTAssertEqual(retryPolicy.delay(forAttempt: 0), 0.0)
        XCTAssertEqual(retryPolicy.delay(forAttempt: 1), 2.0)
        XCTAssertEqual(retryPolicy.delay(forAttempt: 2), 4.0)
        XCTAssertEqual(retryPolicy.delay(forAttempt: 3), 6.0) // Even though it's beyond max, the calculation should work
    }
    
    func testCustomRetryPolicy() {
        // Given
        var retryPolicy = DefaultRetryPolicy()
        retryPolicy.maxRetryAttempts = 5
        
        // Then
        XCTAssertEqual(retryPolicy.maxRetryAttempts, 5)
        XCTAssertEqual(retryPolicy.delay(forAttempt: 3), 6.0)
        XCTAssertEqual(retryPolicy.delay(forAttempt: 4), 8.0)
    }
}
