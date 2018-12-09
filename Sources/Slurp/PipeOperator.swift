import Foundation
import RxSwift

precedencegroup ForwardApplication {
    associativity: left
}

infix operator |>: ForwardApplication

public func |> <T, S: SlurpTask>(lhs: Observable<T>, rhs: S) -> Observable<S.OutputType> {
    return lhs.flatMap { _ in
        return rhs.start()
    }
}

public func |> <S: SlurpTask>(lhs: Slurp, rhs: S) -> Observable<S.OutputType> {
    return lhs.startWith(rhs)
}

// String piping
public func |> <T> (lhs: Observable<T>, rhs: String) -> Observable<Shell.OutputType> {
    return lhs.asVoid() |> Shell(rhs)
}

public func |> (lhs: Slurp, rhs: String) -> Observable<Shell.OutputType> {
    return lhs |> Shell(rhs)
}

infix operator ^>: ForwardApplication

public func ^> <T, S: SlurpTask>(lhs: Observable<T>, rhs: S) -> Observable<S.OutputType> where S.InputType == T {
    return lhs.pipe(to: rhs)
}

@available(*, unavailable, message: "OutputType of the previous task doesnt match. Use |> to ignore input.")
public func ^> <T, S: SlurpTask>(lhs: Observable<T>, rhs: S) -> Observable<S.OutputType> {
    fatalError()
}

@available(*, unavailable, message: "Shell commands don't take input. Use |> to ignore input.")
public func ^> <T> (lhs: Observable<T>, rhs: String) -> Observable<Shell.OutputType> {
    fatalError()
}
