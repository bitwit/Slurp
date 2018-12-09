import Foundation
import RxSwift
import PathKit

public enum SlurpError: Error {
    case taskNotFound
}

public class Slurp {
    
    public static var processType: SlurpShellProcess.Type = Process.self
    public static var currentWorkingDirectory: String? = ProcessInfo().environment["SLURP_CWD"]

    public var watchers: [Watcher] = []
    public var tasks: [String: RegisteredTask] = [:]

    public init() {
        if let dir = Slurp.currentWorkingDirectory {
            Path.current = Path(dir)
        }
    }

    public func watch(paths: [String], recursive: Bool = false) -> Observable<Void> {
        let watcher = Watcher(globs: paths, recursive: recursive)
        watchers.append(watcher)
        return watcher.asObservable()
    }

    @discardableResult
    public func register<S: SlurpTask>(_ name: String, _ dependencies: [String], _ task: S) -> Slurp {
        tasks[name] = RegisteredTask(name: name, dependencies: dependencies, task: task)
        return self
    }

    @discardableResult
    public func register<S: SlurpTask>(_ name: String, _ task: S) -> Slurp {
        tasks[name] = RegisteredTask(name: name, dependencies: [], task: task)
        return self
    }

    @discardableResult
    public func register<T>(_ name: String, _ dependencies: [String], _ taskCreator: (Slurp) -> Observable<T>) -> Slurp {
        let task = BasicTask<Void, Void>(observable: taskCreator(self).asVoid())
        tasks[name] = RegisteredTask(name: name, dependencies: dependencies, task: task)
        return self
    }

    @discardableResult
    public func register<T>(_ name: String, _ taskCreator: (Slurp) -> Observable<T>) -> Slurp {
        return register(name, [], taskCreator)
    }

    public func startWith<S: SlurpTask>(_ task: S) -> Observable<S.OutputType> {
        return task.start()
    }

    public func run(taskName: String) -> Observable<Void> {

        guard let task = tasks[taskName] else {
            return Observable.error(SlurpError.taskNotFound)
        }
        
        print("\n----- Starting Task: \(task.name) \n")
        
        let dependenciesObservable = task.dependencies.reduce(Observable.just(())) { obs, taskName in
            return obs.flatMap {
                return self.run(taskName: taskName)
            }
        }

        return dependenciesObservable
            .flatMap { _ -> Observable<Void> in
                return task.observable
            }
            .asVoid()
    }

    public func runAndExit(taskName: String) throws {
        var disposeBag: DisposeBag? = DisposeBag()
        let disposable = run(taskName: taskName).subscribe({ (event) in
            switch event {
            case .next:
                print("✅ \(taskName) done")
                exit(0)
            case .error(let e):
                print("🚫 \(taskName) failed:")
                print(e)
                exit(1)
            default: break
            }
            disposeBag = nil
        })
        disposeBag?.insert(disposable)
        RunLoop.main.run()
    }
    
    public func runAndExit<T>(_ taskCreator: (Slurp) -> Observable<T>) throws {
        let name = "__Slurp_task"
        let task = BasicTask<Void, Void>(observable: taskCreator(self).asVoid())
        tasks[name] = RegisteredTask(name: name, dependencies: [], task: task)
        try runAndExit(taskName: name)
    }

}
