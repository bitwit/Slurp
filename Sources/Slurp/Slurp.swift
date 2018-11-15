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
    public func register<T>(_ name: String, _ dependencies: [String], _ taskCreator: () -> Observable<T>) -> Slurp {
        let task = BasicTask(observable: taskCreator())
        tasks[name] = RegisteredTask(name: name, dependencies: dependencies, task: task)
        return self
    }

    @discardableResult
    public func register<T>(_ name: String, _ taskCreator: () -> Observable<T>) -> Slurp {
        return register(name, [], taskCreator)
    }

    public func startWith<S: SlurpTask>(_ task: S) -> Observable<S.OutputType> {
        print("\n----- Running \(task.name) \n")
        return task.onPipe(from: ())
    }

    public func run(taskName: String) -> Observable<Void> {

        guard let task = tasks[taskName] else {
            return Observable.error(SlurpError.taskNotFound)
        }

        let dependentTasks = task.dependencies.map { run(taskName: $0) }

        let initialObservable: Observable<Void>
        if dependentTasks.isNotEmpty {
            initialObservable = Observable
                .combineLatest(dependentTasks)
                .asVoid()
        } else {
            initialObservable = Observable.just(())
        }

        return initialObservable
            .flatMap { _ -> Observable<Void> in
                return task.observable
            }
            .map { _ in
                print("Task \(taskName) completed")
            }
            .asVoid()
    }

    public func runAndExit(taskName: String) throws {
        guard let task = tasks[taskName] else {
            throw SlurpError.taskNotFound
        }

        var disposeBag: DisposeBag? = DisposeBag()
        let disposable = task.observable.subscribe({ (event) in
            switch event {
            case .next:
                print(taskName + " done")
                exit(0)
            case .error(let e):
                print(taskName + " error:", e)
                exit(1)
            default: break
            }
            disposeBag = nil
        })
        disposeBag?.insert(disposable)
        RunLoop.main.run()
    }

}
