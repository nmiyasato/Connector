//
//  File.swift
//  
//
//  Created by Nicolas Miyasato on 13/10/2023.
//

import Foundation

public protocol RetryPolicy {
    var maxRetryAttempts: Int { get }
    func delay(forAttempt attempt: Int) -> TimeInterval
}

public struct DefaultRetryPolicy: RetryPolicy {
    public var maxRetryAttempts: Int = 3

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        return 2.0 * Double(attempt)
    }
}
