import Foundation
import Slurp
import RxSwift
import PathKit

open class XcodeBuild: SlurpTask {
    
    public enum SDK: String {
        case ios = "iphoneos"
    }
    
    public enum Action {
        case test
        case archive
        case export
    }
    
    public struct Config {
        
        var workspace: String?
        var scheme: String?
        var destination: String?
        
        var sdk: SDK = .ios
        
        var testDestination: String = "platform=iOS Simulator,name=iPhone 6s Plus,OS=latest"
        
        var archivePath: String?
        
        var exportPath: String?
        var exportOptionsPlist: String?
        
        public init(workspace: String? = nil
            , scheme: String? = nil
            , destination: String? = nil
            , testDestination: String? = nil
            , archivePath: String? = nil
            , exportPath: String? = nil
            , exportOptionsPlist: String? = nil) {
            
            self.workspace = workspace
            self.scheme = scheme
            self.destination = destination
            if let td = testDestination {
                self.testDestination = td
            }
            
            self.archivePath = archivePath
            
            self.exportPath = exportPath
            self.exportOptionsPlist = exportOptionsPlist
        }
    }
    
    var observable: Observable<Void>

    public init(_ actions: [Action], config: Config? = nil) {
        
        self.observable = actions.reduce(Observable.just(())) {
            (observable, action) -> Observable<Void> in
            return observable.flatMap { _ in
                return XcodeBuild.buildObservable(for: action, config: config)
            }
        }
    }
    
    public func onPipe<U>(from input: U) -> Observable<Void> {
       return observable
    }
    
    private static func buildObservable(for action: Action, config: Config?) -> Observable<Void> {
        
        var arguments = ["xcodebuild"]
        
        guard let conf = config else {
            return Shell(arguments: arguments).observable.asVoid()
        }
        
        switch action {
        case .test:
            arguments += ["test", "-destination", conf.testDestination]
            arguments += conf.workspace.map({ ["-workspace", Path($0).absolute().string] }) ?? []
            arguments += conf.scheme.map({ ["-scheme", $0] }) ?? []
        case .archive:
            arguments += ["archive"]
            arguments += conf.workspace.map({ ["-workspace", Path($0).absolute().string] }) ?? []
            arguments += conf.scheme.map({ ["-scheme", $0] }) ?? []
            arguments += conf.archivePath.map({ ["-archivePath", Path($0).absolute().string] }) ?? []
        case .export:
            arguments += ["-exportArchive"]
            arguments += conf.archivePath.map({ ["-archivePath", Path($0).absolute().string] }) ?? []
            arguments += conf.exportPath.map({ ["-exportPath", Path($0).absolute().string] }) ?? []
            arguments += conf.exportOptionsPlist.map({ ["-exportOptionsPlist", $0] }) ?? []
        }
        
//        arguments += ["-sdk", conf.sdk.rawValue]
        
        return Shell(arguments: arguments).observable.asVoid()
    }
}
