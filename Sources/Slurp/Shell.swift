import Foundation
import RxSwift
import ShellOut
import PathKit

public protocol SlurpShellProcess: class {

    var launchPath: String? { get set }
    var environment: [String : String]? { get set }
    var arguments: [String]? { get set }
    var terminationStatus: Int32 { get }

    var standardInput: Any? { get set }
    var standardOutput: Any? { get set }
    var standardError: Any? { get set }
    
    var currentWorkingDirectory: String? { get set }
    var terminationBlock: ((SlurpShellProcess) -> Swift.Void)? { get set }

    init()
    func launch()
}

extension Process: SlurpShellProcess {
    
    public var currentWorkingDirectory: String? {
        get {
            if #available(OSX 10.13, *) {
                return currentDirectoryURL?.absoluteString
            } else {
                return nil
            }
        }
        set {
            if #available(OSX 10.13, *) {
                currentDirectoryURL = newValue.map({ URL(fileURLWithPath: $0) })
            }
        }
    }
    
    public var terminationBlock: ((SlurpShellProcess) -> Swift.Void)? {
        get {
            fatalError("Can't access terminationBlock on Process. You can set it and check for its existence on a real Process via its enclosing `terminationHandler`. Using this getter is a programming error.")
        }
        set {
            if let handler = newValue {
                self.terminationHandler = { handler($0) }
            } else {
                self.terminationHandler = nil
            }
        }
    }
}

open class Shell: SlurpTask {

    public var observable: Observable<(Int32, String?)> = Observable.empty()
    
    public static func createObservable(arguments: [String]) -> Observable<(Int32, String?)> {
        return Observable<(Int32, String?)>.create({ (observer) -> Disposable in
            
            let command = arguments.joined(separator: " ")
            print("$", command)
            
            let process = Slurp.processType.init()
            process.launchPath = "/bin/bash"
            process.arguments = ["-c", command]
            
            if let cwd = Slurp.currentWorkingDirectory {
                process.currentWorkingDirectory = Path(cwd).absolute().string
            }

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            var allData = Data()
            
            let mainStdOutHandle = FileHandle.standardOutput
            
            pipe.fileHandleForReading.readabilityHandler = { handler in
                let data = handler.availableData
                guard data.isNotEmpty else { return }
                allData.append(data)
                mainStdOutHandle.write(data)
            }
            process.terminationBlock = { process in
                pipe.fileHandleForReading.closeFile()
                let output = String(data: allData, encoding: .utf8)
                
                if process.terminationStatus == 0 {
                    observer.onNext( (process.terminationStatus, output) )
                    observer.onCompleted()
                } else {
                    observer.onError(SlurpTaskError.shellProcessExitedWithNonZero(process.terminationStatus, output))
                }
            }
            
            process.launch()
            return Disposables.create()
        })
    }

    public init(_ command: String) {
        self.observable = Shell.createObservable(arguments: [command])
    }
    
    public init(arguments: [String]) {
        self.observable = Shell.createObservable(arguments: arguments)
    }

    open func onPipe<U>(from input: U) -> Observable<(Int32, String?)> {
        return observable
    }
    
    //Shell out support
    
    public static func createObservable(shellOutCommand: ShellOutCommand) -> Observable<(Int32, String?)> {
        return createObservable(arguments: [shellOutCommand.string])
    }
    
    public init(_ shellOutCommand: ShellOutCommand) {
        self.observable = Shell.createObservable(shellOutCommand: shellOutCommand)
    }

}
