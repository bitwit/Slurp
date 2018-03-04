import Foundation
import Slurp

public class Version: Shell {
        
    public enum Action {
        case setMarketingVersion(String)
        case setBuildNumber(String)
        case incrementBuildNumber
    }
    
    public init( _ action: Action, all: Bool = false) {
        var arguments = ["agvtool"]
        
        switch action {
        case .setMarketingVersion(let marketingVersion):
            arguments += ["new-marketing-version", marketingVersion]
        case .setBuildNumber(let buildNumber):
            arguments += ["new-version", buildNumber]
            arguments += all ? ["-all"] : []
        case .incrementBuildNumber:
            arguments += ["next-version"]
            arguments += all ? ["-all"] : []
        }

        super.init(arguments: arguments)
    }
    
}
