import Foundation

/// A basic implementation of CancellableDataProvider that uses the actor-based TaskManager
public class StandardDataProvider: DataProvider {
    public var retryPolicy: RetryPolicy?
    public let taskManager: TaskManager
    
    public init(retryPolicy: RetryPolicy? = nil) {
        self.retryPolicy = retryPolicy
        self.taskManager = TaskManager()
    }
}
