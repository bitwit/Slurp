import Foundation
import Guaka
import MarathonCore
import ShellOut
import Slurp

struct SlurpCommands {
    
    static func execute() {
        let mainCommand = Command(usage: "slurp")
        mainCommand.flags = [
            Flag(shortName: nil,
                 longName: "verbose",
                 value: false,
                 description: "enable verbose printing",
                 inheritable: true)
        ]
        mainCommand.run = runSlurpfile
        mainCommand.add(subCommand: createInitCommand())
        mainCommand.add(subCommand: createEditCommand())
        mainCommand.execute()
    }
    
    private static func createInitCommand() -> Command {
        
        let initCommand = Command(usage: "init")
        initCommand.shortMessage = "Create a new slurp tasks package & xcode project"
        initCommand.longMessage = """
        
        🆕  - Init
        Creates a new SlurpTasks package and xcode project
        """
        initCommand.run = self.newSlurpTasksPackage
        
        return initCommand
    }
    
    private static func createEditCommand() -> Command {
        
        let editCommand = Command(usage: "edit")
        editCommand.shortMessage = "(Experimental) Open an xcodeproj for your Slurpfile"
        editCommand.longMessage = """
        
        ✏️  - Edit (Experimental)
        Creates and then opens an xcodeproj exclusively for this file.
        The main.swift file will be watched and written back to your Slurpfile.swift
        """
        editCommand.run = self.editSlurpfile
        
        return editCommand
    }
    
    private static func runSlurpfile(_ flags: Flags, args: [String]) {
        do {
            let projMgr = try SlurpProjectManager(verbose: flags.getBool(name: "verbose") ?? false)
            try projMgr.run()
        } catch {
            print("Error".consoleText(color: .red))
            print(error.localizedDescription.consoleText(color: .red))
        }
    }
    
    private static func newSlurpTasksPackage(_ flags: Flags, args: [String]) {
        do {
            let projMgr = try SlurpProjectManager(verbose: flags.getBool(name: "verbose") ?? false)
            try projMgr.generate()
        } catch {
            if let e = error as? PackageManagerError {
                print((e.message + e.hints.joined(separator: "\n")).consoleText(color: .red))
            }
            print("Error".consoleText(color: .red))
            print(error.localizedDescription.consoleText(color: .red))
        }
    }
    
    private static func editSlurpfile(_ flags: Flags, args: [String]) {
        do {
            let projMgr = try SlurpProjectManager(verbose: flags.getBool(name: "verbose") ?? false)
            try projMgr.openInXcode()
        } catch {
            print("Error".consoleText(color: .red))
            print(error.localizedDescription.consoleText(color: .red))
        }
    }
    
    
}


