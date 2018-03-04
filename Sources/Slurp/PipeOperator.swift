import Foundation
import RxSwift

infix operator |>: MultiplicationPrecedence

public func |> <T, S: SlurpTask>(lhs: Observable<T>, rhs: S) -> Observable<S.OutputType> {
    return lhs.pipe(to: rhs)
}

public func |> <S: SlurpTask>(lhs: Slurp, rhs: S) -> Observable<S.OutputType> {
    return lhs.startWith(rhs)
}
