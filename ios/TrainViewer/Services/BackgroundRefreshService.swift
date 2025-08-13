import Foundation
import BackgroundTasks

final class BackgroundRefreshService {
    static let shared = BackgroundRefreshService()
    private init() {}

    static let taskIdentifier = "com.yourcompany.trainviewer.refresh"

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            self.handle(task: task as! BGAppRefreshTask)
        }
    }

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do { try BGTaskScheduler.shared.submit(request) } catch { }
    }

    private func handle(task: BGAppRefreshTask) {
        schedule() // schedule next
        let queue = OperationQueue()
        let op = RefreshOperation()
        task.expirationHandler = {
            op.cancel()
        }
        op.completionBlock = {
            task.setTaskCompleted(success: !op.isCancelled)
        }
        queue.addOperation(op)
    }
}

final class RefreshOperation: Operation {
    override func main() {
        if isCancelled { return }
        Task.detached {
            let vm = RoutesViewModel()
            await vm.refreshAll()
            BackgroundRefreshService.shared.schedule()
        }
        // Allow some time; in production, use semaphores to wait or refactor to BGProcessingTask if needed.
        Thread.sleep(forTimeInterval: 3)
    }
}