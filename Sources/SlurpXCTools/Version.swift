import Foundation
import Slurp
import RxSwift

public class Version: SlurpTask {

    public typealias InputType = String
    public typealias OutputType = Void
    
    public enum Action {
        case setMarketingVersion(String?)
        case setBuildNumber(String?)
        case incrementBuildNumber
    }
    
    let action: Action
    let all: Bool
    public let runMessage: String? = nil
    
    public init( _ action: Action, all: Bool = false) {
        self.action = action
        self.all = all
    }
    
    public func start() -> Observable<Void> {
        return buildVersionCommand(versionString: nil)
    }
    
    public func onPipe(from input: String) -> Observable<Void> {
        let cleanVersionString = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return buildVersionCommand(versionString: cleanVersionString)
    }
    
    private func buildVersionCommand(versionString: String?) -> Observable<Void> {
        
        var arguments = ["agvtool"]
        
        switch action {
        case .setMarketingVersion(let marketingVersion):
            guard let finalVersion = (marketingVersion ?? versionString) else {
                return Observable.error(SlurpTaskError.unexpectedInput("No marketing version provided"))
            }
            arguments += ["new-marketing-version", finalVersion]
        case .setBuildNumber(let buildNumber):
            guard let finalVersion = (buildNumber ?? versionString) else {
                return Observable.error(SlurpTaskError.unexpectedInput("No build number provided"))
            }
            arguments += ["new-version"]
            arguments += all ? ["-all"] : []
            arguments += [finalVersion]
        case .incrementBuildNumber:
            arguments += ["next-version"]
            arguments += all ? ["-all"] : []
        }
        
        return Shell(arguments: arguments).observable.asVoid()
    }
    
}
