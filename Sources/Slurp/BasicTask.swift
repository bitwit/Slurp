import Foundation
import RxSwift
import PathKit

public enum SlurpTaskError: Error {
    case noFile
    case asyncTaskYieldedNoResultOrError
    case shellProcessExitedWithNonZero(Int32, String?)
    case unexpectedInput(String)
    case taskDeallocated
    case unspecified
}

public protocol SlurpTask {

    associatedtype InputType
    associatedtype OutputType

    var name: String { get }
    var runMessage: String? { get }
    
    func start() -> Observable<OutputType>
    func onPipe(from input: InputType) -> Observable<OutputType>
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
        self.observable = task.start().asVoid()
    }
}

open class BasicTask<I,O>: SlurpTask {
    
    public typealias InputType = I
    public typealias OutputType = O

    public let observable: Observable<O>
    public var runMessage: String?

    public init(observable: Observable<O>) {
        self.observable = observable
    }

    public init(asyncTask: @escaping ( (Error?, O?) -> Void ) -> Void) {
        let observable = Observable<O>.create { (observer) -> Disposable in
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
    
    public func start() -> Observable<O> {
        return observable
    }

    public func onPipe(from input: I) -> Observable<O> {
        return observable
    }
}

public class CWD: BasicTask<Void, Void> {
    public init(_ newDir: String) {
        super.init { callback in
            Slurp.currentWorkingDirectory = newDir
            Path.current = Path(newDir)
            print("Current Working Directory set to \(newDir)")
            callback(nil, ())
        }
    }
}
