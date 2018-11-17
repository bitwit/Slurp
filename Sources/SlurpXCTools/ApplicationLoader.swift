import Foundation
import Slurp
import RxSwift
import PathKit

public class ApplicationLoader: Shell {
    
    static var alToolPath: String = "/Applications/Xcode.app/Contents/Applications/Application\\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/altool"
    
    public enum Action: String {
        case uploadApp = "--upload-app"
        case validateApp = "--validate-app"
    }
    
    public enum Platform: String {
        case ios
        case tvos = "appletvos"
        case osx
    }
    
    public struct Config {
        
        var file: String
        var platform: Platform
        var username: String
        
        //May use @keychain: or @env: prefixes followed by the keychain or environment variable lookup name.
        //e.g. -p @env:SECRET which would use the value in the SECRET environment variable.
        var password: String
        var outputFormat: String?
        
        public init(file: String, platform: Platform = .ios, username: String, password: String, outputFormat: String? = nil) {
            self.file = file
            self.platform = platform
            self.username = username
            self.password = password
            self.outputFormat = outputFormat
        }
    }
    
    public init(_ action: Action, config: Config) {
        
        let file = Path(config.file).absolute().string
        var arguments = [
            ApplicationLoader.alToolPath,
            action.rawValue,
            "--type", "\(config.platform.rawValue)",
            "--file", "\(file)",
            "--username", "\(config.username)",
            "--password", "\(config.password)"
        ]
        
        if let of = config.outputFormat {
            arguments += ["--output-format", of]
        }
        
        super.init(arguments: arguments)
    }
    
    public override func onPipe<U>(from input: U) -> Observable<String> {
        print("\n--- Uploading App, this may take several minutes\n")
        return super.onPipe(from: input)
    }
    
}
