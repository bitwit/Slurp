import Foundation
import MarathonCore
import Files
import Slurp

public class SlurpProjectManager {
    
    let rootFolder: Folder
    let slurpFolder: Folder
    
    let packageInfoFolder: Folder
    let packageManager: PackageManager
    
    let printer: Printer
    
    public init(verbose: Bool) throws {
        
        printer = Printer(outputFunction: { print($0) },
                          progressFunction: { (message: () -> String) in if verbose { print(message()) } },
                          verboseFunction: { (message: () -> String) in if verbose { print(message()) } })
        
        rootFolder = try Folder(path: FileManager.default.currentDirectoryPath)
        slurpFolder = try rootFolder.createSubfolderIfNeeded(withName: "Slurp")
        
        packageInfoFolder = try slurpFolder.createSubfolderIfNeeded(withName: "Packages")
        packageManager = try PackageManager(folder: packageInfoFolder, printer: printer)
    }
    
    deinit {
        do {
            try packageInfoFolder.delete()
        } catch {
            print("Warning: Couldn't delete packages folder".consoleText(color: .red))
        }
    }
    
    func generate() throws {
        
        let projectName = "SlurpTasks"
        
        let cloneFolder = try Folder(path: "~/Development/personal/Slurp") //Folder(path: "~/.slurp/clone")
        let cloneFolderUrl = URL(string: cloneFolder.path)!
        
        let script = Script(name: projectName, folder: slurpFolder, dependencies: [
            Dependency(name: "Slurp", url: cloneFolderUrl),
            Dependency(name: "SlurpXCTools", url: cloneFolderUrl)
        ], printer: printer)
        
        script.dependencies = try packageManager.addPackagesIfNeeded(from: script.dependencies)
        
        let packageFile = try slurpFolder.createFile(named: "Package.swift")
        try packageFile.write(string: packageManager.makePackageDescription(for: script))
        
        let sourcesFolder = try slurpFolder.createSubfolderIfNeeded(withName: "Sources")
        let slurpTasksFolder = try sourcesFolder.createSubfolderIfNeeded(withName: projectName)
        let file = try slurpTasksFolder.createFileIfNeeded(withName: "main.swift")
        try file.write(string: "import Foundation\n\n print(\"Hello World!\")")
        
        try generateXcodeProject()
    }
    
    func run() throws {
        try Slurp()
        .register("RunTask") {
            return Shell("cd Slurp && swift run").observable
        }
        .runAndExit(taskName: "RunTask")
    }
    
    func openInXcode() throws {
        try generateXcodeProject()
        try Slurp()
            .register("Edit") {
                return Shell("cd Slurp && open SlurpTasks.xcodeproj").observable
            }
            .runAndExit(taskName: "Edit")
    }
    
    private func generateXcodeProject() throws {
        try Slurp()
            .register("RunTask") {
                return Shell("cd Slurp && package generate-xcodeproj").observable
            }
            .runAndExit(taskName: "RunTask")
    }
    
}
