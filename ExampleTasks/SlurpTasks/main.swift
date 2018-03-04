import Foundation
import Slurp
import SlurpXCTools

// Slurp.currentWorkingDirectory = "/path/to/cwd"

let xcBuildConfig = XcodeBuild.Config(
    scheme: "SlurpExampleApp",
    archivePath: "example.xcarchive",
    exportPath: "example.ipa",
    exportOptionsPlist: "ExportOptions.plist"
)

let uploadConfig = ApplicationLoader.Config(
    file: "example.ipa/SlurpExampleApp.ipa",
    username: "",
    password: ""
)

let slurp = Slurp()
slurp
    .register("buildAndDeploy") {
        return slurp
            |> Version(.incrementBuildNumber, all: true)
            |> Version(.setMarketingVersion("1.0.1"), all: true)
            |> XcodeBuild([.archive, .export], config: xcBuildConfig)
            |> ApplicationLoader(.uploadApp, config: uploadConfig)
    }

try! slurp.runAndExit(taskName: "buildAndDeploy")
