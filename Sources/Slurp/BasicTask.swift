import Foundation
import RxSwift
import ShellOut

public enum SlurpTaskError: Error {
    case unexpectedInput
    case noFile
    case asyncTaskYieldedNoResultOrError
    case shellProcessExitedWithNonZero(Int32, String?)
    case taskDeallocated
    case unspecified
}

public protocol SlurpTask {

    associatedtype OutputType

    var name: String { get }
    
    func onPipe<U>(from input: U) -> Observable<OutputType>
}

extension SlurpTask {
    
    public var name: String {
        return String(describing: self)
    }
}

public class RegisteredTask {

    let name: String
    var dependencies: [String]
    let observable: Observable<Void>

    public init<S: SlurpTask>(name: String, dependencies: [String] = [], task: S) {
        self.name = name
        self.dependencies = dependencies
        self.observable = task.onPipe(from: ()).asVoid()
    }
}

open class BasicTask<T>: SlurpTask {

    public let observable: Observable<T>

    public init(observable: Observable<T>) {
        self.observable = observable
    }

    public init(asyncTask: @escaping ( (Error?, T?) -> Void ) -> Void) {
        let observable = Observable<T>.create { (observer) -> Disposable in
            asyncTask {
                err, value in
                if let error = err {
                    observer.onError(error)
                } else if let result = value {
                    observer.onNext(result)
                } else {
                    observer.onError(SlurpTaskError.asyncTaskYieldedNoResultOrError)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
        self.observable = observable
    }

    public func onPipe<U>(from input: U) -> Observable<T> {
        return observable
    }
}

public class CWD: BasicTask<Void> {
    public init(_ newDir: String) {
        Slurp.currentWorkingDirectory = newDir
        super.init { callback in
            callback(nil, ())
        }
    }
}
