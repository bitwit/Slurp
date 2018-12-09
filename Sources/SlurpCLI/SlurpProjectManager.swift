import Foundation
import PathKit
import Slurp

enum SlurpCLIError: Error {
    case cantCreateDirectory
    case cantCreateFile
}

extension Path {
    func createSubfolderIfNeeded(named name: String) throws -> Path {
        let path = self + Path(name)
        if path.isFile {
            throw SlurpCLIError.cantCreateDirectory
        } else if !path.exists {
            try path.mkdir()
        }
        return path
    }
}

public class SlurpProjectManager {
    
    let rootFolder: Path
    let slurpFolder: Path
    
    let verbose: Bool

    public init(verbose: Bool) throws {
        self.rootFolder = Path(FileManager.default.currentDirectoryPath)
        self.slurpFolder = try rootFolder.createSubfolderIfNeeded(named: "Slurp")
        self.verbose = verbose
    }
    
    func generate() throws {
        
        let projectName = "SlurpTasks"
        
        var slurpFolderPath = "~/.slurp/clone"
        if let path = ProcessInfo().environment["SLURP_MODULE_PATH"] {
            slurpFolderPath = path
        }
        
        let cloneFolder = Path(slurpFolderPath)
        let cloneFolderUrl = cloneFolder.url
        
        let script = PackageDescriptionBuilder(name: projectName, folder: slurpFolder, dependencies: [
            Dependency(name: "Slurp", url: cloneFolderUrl),
            Dependency(name: "SlurpXCTools", url: cloneFolderUrl)
        ])
        
        let packageFile = slurpFolder + Path("Package.swift")
        try packageFile.write(script.generate())
        
        let sourcesFolder = try slurpFolder.createSubfolderIfNeeded(named: "Sources")
        let slurpTasksFolder = try sourcesFolder.createSubfolderIfNeeded(named: projectName)
        let mainFile = slurpTasksFolder + Path("main.swift")
        try mainFile.write("import Foundation\n\n print(\"Hello World!\")")
        
        try generateXcodeProject()
    }
    
    func run() throws {
        try Slurp().register("RunTask") {
            return $0 |> Shell("cd Slurp && swift run")
        }
        .runAndExit(taskName: "RunTask")
    }
    
    func openInXcode() throws {
        try generateXcodeProject()
        try Slurp().register("Edit") {
                return $0 |> Shell("cd Slurp && open SlurpTasks.xcodeproj")
            }
            .runAndExit(taskName: "Edit")
    }
    
    private func generateXcodeProject() throws {
        try Slurp().register("RunTask") {
                return $0 |> Shell("cd Slurp && swift package generate-xcodeproj")
            }
            .runAndExit(taskName: "RunTask")
    }
    
}
