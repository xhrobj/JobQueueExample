//
//  JobScheduler.swift
//  JobQueue
//
//

import Foundation

final class JobScheduler {
    
    private let jobQueue = JobQueue()
    private let isolatedQueue = DispatchQueue(label: "isolated", attributes: .concurrent)
    private var isStopped = true
    
    private var isActive: Bool {
        get {
            isolatedQueue.sync {
                !isStopped
            }
        }
        set {
            isolatedQueue.async(flags: .barrier) {
                self.isStopped = !newValue
            }
        }
    }
    
    func cancel(jobId: JobId) {
        isolatedQueue.async(flags: .barrier) {
            let job = self.jobQueue.remove(with: jobId)
            job?.group?.leave()
        }
    }
    
    func cancelAll() {
        isolatedQueue.async(flags: .barrier) {
            self.jobQueue.jobList.forEach {
                $0.group?.leave()
            }
            self.jobQueue.clear()
        }
    }
    
    func schedule(job: Job) {
        job.group?.enter()
        isolatedQueue.async(flags: .barrier) {
            self.jobQueue.enqueue(job: job)
        }
    }
    
    func start() {
        isActive = true
        main()
    }
    
    func stop() {
        isActive = false
    }
    
    private func main() {
        DispatchQueue.global().async { [weak self] in
            while self?.isActive ?? false {
                self?.startNextJob()
            }
        }
    }
    
    private func startNextJob() {
        isolatedQueue.async(flags: .barrier) {
            if var job = self.jobQueue.poll() {
                job.start()
                job.group?.leave()
            }
        }
    }
}
