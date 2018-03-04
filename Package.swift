// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Slurp",
    products: [
		   .library(name: "Slurp", targets: ["Slurp"]),
		   .library(name: "SlurpXCTools", targets: ["SlurpXCTools"])
	],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .exact(.init(4, 1, 2))),
        .package(url: "https://github.com/kylef/PathKit.git", .exact(.init(0, 9, 0))),

        // Testing
        .package(url: "https://github.com/Quick/Quick.git", .exact(.init(1, 2, 0))),
        .package(url: "https://github.com/Quick/Nimble.git", .exact(.init(7, 0, 3)))
    ],
    targets: [
        .target(
            name: "Slurp",
            dependencies: ["RxSwift", "PathKit"]),
        .target(
            name: "SlurpXCTools",
            dependencies: ["Slurp", "RxSwift", "PathKit"]),

        .testTarget(
          name: "SlurpTests",
          dependencies: ["Quick", "Nimble", "Slurp"]
        ),

        // Example
        .target(
            name: "SlurpTasks",
            dependencies: ["Slurp", "SlurpXCTools"],
            path: "ExampleTasks")

    ]
)
