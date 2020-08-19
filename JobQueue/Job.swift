//
//  Job.swift
//  JobQueue
//

import Foundation

typealias JobId = String
typealias Action = () -> Void

enum JobStatus: Equatable {
    case waiting
    case started(at: Date)
    case active
    case completed(at: Date)
    case paused
    
    public var isActive: Bool {
        switch self {
        case .active:
            return true
        default:
            return false
        }
    }
}

protocol Job {
    var id: JobId { get }
    var status: JobStatus { get }
    var group: DispatchGroup? { get }
    mutating func start()
}

struct JobImpl: Job {
    
    let id: JobId
    let action: Action
    let group: DispatchGroup?
    var status = JobStatus.waiting
    
    init(id: String, group: DispatchGroup?, _ action: @escaping Action) {
        self.id = id
        self.group = group
        self.action = action
    }
    
    mutating func start() {
        status = .completed(at: Date())
        status = .active
        action()
        status = .completed(at: Date())
    }
}
