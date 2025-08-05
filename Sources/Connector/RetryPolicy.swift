//
//  RetryPolicy.swift
//
//
//  Created by Nicolas Miyasato on 13/10/2023.
//

import Foundation

/// @mockable
public protocol RetryPolicy: Sendable {
    var maxRetryAttempts: Int { get }
    func delay(forAttempt attempt: Int) -> TimeInterval
}

public struct DefaultRetryPolicy: RetryPolicy, @unchecked Sendable {
    public var maxRetryAttempts: Int
    
    public init(maxRetryAttempts: Int = 3) {
        self.maxRetryAttempts = maxRetryAttempts
    }

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        return 2.0 * Double(attempt)
    }
}
