import Foundation
import RxSwift

public enum SlurpTaskError: Error {
    case unexpectedInput
    case noFile
    case asyncTaskYieldedNoResultOrError
    case shellProcessExitedWithNonZero(Int32, String?)
    case taskDeallocated
}

public protocol SlurpTask {
    
    associatedtype OutputType
    
    func onPipe<U>(from input: U) -> Observable<OutputType>
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
    
    public convenience init(asyncTask: @escaping ( (Error?, T?) -> Void ) -> Void) {
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
        self.init(observable: observable)
    }
    
    public func onPipe<U>(from input: U) -> Observable<T> {
        return observable
    }
}
