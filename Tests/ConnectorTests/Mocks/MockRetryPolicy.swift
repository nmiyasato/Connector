import Foundation
@testable import Connector

class MockRetryPolicy: RetryPolicy {
    var maxRetryAttempts: Int
    var delayToReturn: TimeInterval
    var delayCallCount = 0
    
    init(maxRetryAttempts: Int = 3, delayToReturn: TimeInterval = 1.0) {
        self.maxRetryAttempts = maxRetryAttempts
        self.delayToReturn = delayToReturn
    }
    
    func delay(forAttempt attempt: Int) -> TimeInterval {
        delayCallCount += 1
        return delayToReturn
    }
}