import Foundation
import PathKit

struct Dependency {
    let name: String
    let url: URL
}

struct PackageDescriptionBuilder {
    let name: String
    let folder: Path
    var dependencies: [Dependency]

    func generate() -> String{
        let header = "// swift-tools-version:4.2\n"

        var description = "\(header)\n\n" +
            "import PackageDescription\n\n" +
            "let package = Package(\n" +
            "    name: \"\(name)\",\n" +
            "    products: [],\n" +
        "    dependencies: [\n"
        
        let uniqueDependencyUrls = Set(dependencies.map { $0.url })
        
        for (index, dependencyUrl) in uniqueDependencyUrls.enumerated() {
            if index > 0 {
                description += ",\n"
            }
            
            let urlString = dependencyUrl.absoluteString.replacingOccurrences(of: "file://", with: "")
            let dependencyString = ".package(path: \"\(urlString)\")"
            description.append("        \(dependencyString)")
        }
        
        description.append("\n    ],\n")
        description.append("    targets: [.target(name: \"\(name)\", dependencies: [")
        
        if !dependencies.isEmpty {
            description.append("\"")
            let dependencyNames = dependencies.map { $0.name  }
            description.append(dependencyNames.joined(separator: "\", \""))
            description.append("\"")
        }
        
        description.append("])],\n")

        description.append("    swiftLanguageVersions: [.version(\"4.2\")]\n)")

        return description
    }
}
