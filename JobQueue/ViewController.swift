//
//  ViewController.swift
//  JobQueue
//

import UIKit

final class ViewController: UITableViewController {
    
    enum MinMaxState: Int, Comparable {
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case none
        case max
        case min
        
        var color: UIColor {
            switch self {
            case .min:
                return UIColor.green
            case .max:
                return UIColor.red
            default:
                return UIColor.clear
            }
        }
    }
    
    final class CellData {
        let id: String
        let interval: Double
        var minMax: MinMaxState
        
        init(id: String, interval: Double, minMax: MinMaxState) {
            self.id = id
            self.interval = interval
            self.minMax = minMax
        }
    }
    
    private var data: [CellData] = []
    
    private let dispatchGroup = DispatchGroup()
    private lazy var jobScheduler: JobScheduler = {
        let jobScheduler = JobScheduler()
        jobScheduler.start()
        return jobScheduler
    }()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as UITableViewCell
        let item = data[indexPath.row]
       
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.text = "id: \(item.id)"
        cell.detailTextLabel?.text = "время: \(String(item.interval))"
        cell.backgroundColor = item.minMax.color
        return cell
    }
    
    @IBAction func startTests(_ sender: UIButton) {
        data = []
        tableView.reloadData()
        
        (0...10_000).forEach { _ in
            let job = createJob()
            jobScheduler.schedule(job: job)
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.updateMinMax()
            self.tableView.reloadData()
        }
    }
    
    private func createJob() -> Job {
        let id = UUID().uuidString
        let job = JobImpl(id: id, group: dispatchGroup) {
            let start = DispatchTime.now()
            _ = Test(id: id, name: "create")
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            print("create jon \(id)")
            print("Execution time interval: \(timeInterval) seconds")
            
            DispatchQueue.main.async {
                self.data.append(CellData(id: id, interval: timeInterval, minMax: .none))
            }
        }
        return job
    }
    
    private func updateMinMax() {
        self.data.forEach { $0.minMax = .none }
        let minItem = self.data.min(by: { $0.interval < $1.interval })
        let maxItem = self.data.max(by: { $0.interval < $1.interval })
        minItem?.minMax = .min
        maxItem?.minMax = .max
        self.data.sort(by: { $0.minMax > $1.minMax })
    }
}

