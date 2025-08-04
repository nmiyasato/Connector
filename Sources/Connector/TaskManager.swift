//
//  TaskManager.swift
//  Connector
//
//  Created by Nicolas Miyasato on 25/05/2025.
//

import Foundation

// A class-based wrapper for Task to enable identity comparison
public final class TaskWrapper: Sendable {
    let task: Any
    let id: String
    
    init<T>(_ task: Task<T, Error>) {
        self.task = task
        self.id = UUID().uuidString
    }
    
    func cancel() {
        if let typedTask = task as? Task<Any, Error> {
            typedTask.cancel()
        }
    }
}

/// A task manager actor that handles cancellation
public actor TaskManager {
    
    private var activeTasks: [String: [TaskWrapper]] = [:]
    
    public init() {}
    
    public func registerTask(_ wrapper: TaskWrapper, for endpointId: String) {
        if activeTasks[endpointId] == nil {
            activeTasks[endpointId] = []
        }
        
        // Store in wrapper class
        activeTasks[endpointId]?.append(wrapper)
    }
    
    public func unregisterTask(for endpointId: String, taskId: String) {
        activeTasks[endpointId]?.removeAll { wrapper in
            return wrapper.id == taskId
        }
        
        if let tasks = activeTasks[endpointId], tasks.isEmpty {
            activeTasks.removeValue(forKey: endpointId)
        }
    }
    
    public func cancelTasks(for endpointId: String) {
        let tasks = activeTasks[endpointId] ?? []
        for taskWrapper in tasks {
            taskWrapper.cancel()
        }
        activeTasks.removeValue(forKey: endpointId)
    }
    
    public func cancelAllTasks() {
        for (_, tasks) in activeTasks {
            for taskWrapper in tasks {
                taskWrapper.cancel()
            }
        }
        activeTasks.removeAll()
    }
    
    public func getAllEndpointIds() -> [String] {
        return Array(activeTasks.keys)
    }
}
