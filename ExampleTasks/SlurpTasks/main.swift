import Foundation
import Slurp
import SlurpXCTools
import MarathonCore


// Slurp.currentWorkingDirectory = "/path/to/cwd"

//let xcBuildConfig = XcodeBuild.Config(
//    scheme: "SlurpExampleApp",
//    archivePath: "example.xcarchive",
//    exportPath: "example.ipa",
//    exportOptionsPlist: "ExportOptions.plist"
//)
//
//let uploadConfig = ApplicationLoader.Config(
//    file: "example.ipa/SlurpExampleApp.ipa",
//    username: "",
//    password: ""
//)
//
let slurp = Slurp()
slurp
    .register("test") {
        $0
//            |> CWD("~/Development/personal/Slurp")
//            |> Shell(.createFile(named: "testing.cool", contents: "cool"))
//            |> Shell(.removeFile(from: "testing.cool"))
            |> "echo 101"
            |> Version(.setBuildNumber(nil), all: true)
//            |> Version(.setMarketingVersion("1.0.1"), all: true)
//            |> XcodeBuild([.archive, .export], config: xcBuildConfig)
//            |> ApplicationLoader(.uploadApp, config: uploadConfig)
    }

try! slurp.runAndExit(taskName: "test")

