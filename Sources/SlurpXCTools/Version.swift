import Foundation
import Slurp
import RxSwift

public class Version: Shell {
        
    public enum Action {
        case setMarketingVersion(String?)
        case setBuildNumber(String?)
        case incrementBuildNumber
    }
    
    let action: Action
    let all: Bool
    
    public init( _ action: Action, all: Bool = false) {
        self.action = action
        self.all = all
        super.init(arguments: [])
    }
    
    public override func onPipe<U>(from input: U) -> Observable<String> {
        guard let version = input as? String else {
            return buildVersionCommand(versionString: nil)
        }
        let cleanVersionString = version.trimmingCharacters(in: .whitespacesAndNewlines)
        return buildVersionCommand(versionString: cleanVersionString)
    }
    
    private func buildVersionCommand(versionString: String?) -> Observable<String> {
        
        var arguments = ["agvtool"]
        
        switch action {
        case .setMarketingVersion(let marketingVersion):
            guard let finalVersion = (marketingVersion ?? versionString) else {
                fatalError("No marketing version provided")
            }
            arguments += ["new-marketing-version", finalVersion]
        case .setBuildNumber(let buildNumber):
            guard let finalVersion = (buildNumber ?? versionString) else {
                fatalError("No build number provided")
            }
            arguments += ["new-version"]
            arguments += all ? ["-all"] : []
            arguments += [finalVersion]
        case .incrementBuildNumber:
            arguments += ["next-version"]
            arguments += all ? ["-all"] : []
        }
        
        self.arguments = arguments
        return self.observable
    }
    
}
