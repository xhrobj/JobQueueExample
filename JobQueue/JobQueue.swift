//
//  JobQueue.swift
//  JobQueue
//
//

import Foundation

final class JobQueue {
    private(set) var jobList: [Job] = []
    
    func clear() {
        jobList = []
    }
    
    func remove(with jobId: JobId) -> Job? {
        if let index = jobList.firstIndex(where: { $0.id == jobId }) {
            return jobList.remove(at: index)
        }
        return nil
    }
    
    func enqueue(job: Job) {
        if jobList.first(where: { $0.id == job.id }) == nil {
            jobList.append(job)
        }
    }
    
    func poll() -> Job? {
        guard !jobList.isEmpty else {
            return nil
        }
        return jobList.remove(at: 0)
    }
}
