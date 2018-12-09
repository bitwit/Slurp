import Foundation
import RxSwift

extension ObservableType {
    
    /*
     Puts the previous and current value into a tuple together
     i.e.  value -> (previousValue, value)
     */
    public func previousAndCurrentValues() -> Observable<(E, E)> {
        let initalValues: [E] = []
        return scan(initalValues) {
            (previous, next) -> [E] in
            let combined = previous + [next]
            return Array(combined.suffix(2))
            }
            .map {
                latestValues -> (E, E)? in
                guard latestValues.count == 2 else {
                    return nil
                }
                return (latestValues[0], latestValues[1])
            }
            .flatMap {
                value in
                return value.map { Observable.just($0) } ?? Observable.empty()
        }
    }
    
    public func asVoid() -> Observable<Void> {
        return map { _ in () }
    }
    
    public func pipe<S: SlurpTask>(to: S) -> Observable<S.OutputType> where S.InputType == E {
        return flatMap({ (element) -> Observable<S.OutputType> in
            print(E.self, S.InputType.self)
            return to.onPipe(from: element)
        })
    }
    
}

