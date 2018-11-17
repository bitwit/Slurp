import Foundation
import RxSwift

infix operator |>: MultiplicationPrecedence

public func |> <T, S: SlurpTask>(lhs: Observable<T>, rhs: S) -> Observable<S.OutputType> {
    return lhs.pipe(to: rhs)
}

public func |> <S: SlurpTask>(lhs: Slurp, rhs: S) -> Observable<S.OutputType> {
    return lhs.startWith(rhs)
}


// String piping
public func |> <T> (lhs: Observable<T>, rhs: String) -> Observable<Shell.OutputType> {
    return lhs |> Shell(rhs)
}

public func |> (lhs: Slurp, rhs: String) -> Observable<Shell.OutputType> {
    return lhs |> Shell(rhs)
}
