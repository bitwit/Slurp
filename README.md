![Slurp Logo](https://raw.githubusercontent.com/bitwit/Slurp/master/slurp-logo.jpg)

[![Build Status](https://www.bitrise.io/app/000a61c8091db1a1/status.svg?token=HJjORiUavGh7lyVYVx794g&branch=master)](https://www.bitrise.io/app/000a61c8091db1a1)
[![Swift Package Manager Compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Releases](https://img.shields.io/github/tag/bitwit/slurp.svg)](https://github.com/bitwit/Slurp/releases)


A Swift task runner and file watcher with an interface inspired by Gulp.js. Run it from your command line or inside of Xcode

## Contents
- [Intended Uses](#intended-uses)
- [Installation](#installation)
- [Developing and Running in Xcode](#developing-and-running-in-xcode)
- [Available Tasks](#currently-available-tasks)
- [Writing your own task](#writing-your-own-task)
- [The Pipe Operator](#the-pipe-operator)
- [Roadmap](#roadmap)
- [Feedback](#feedback)

## Intended Uses

### For automating workflows
Build your Slurp Task module as an executable. Run it from your CI server, the command line or Xcode. For example, this code builds and deploys an iOS app to the iTunes App Store:

```swift
import Slurp
import SlurpXCTools

let xcBuildConfig = XcodeBuild.Config(...)
let uploadConfig = ApplicationLoader.Config(...)
let slurp = Slurp()
slurp
    .register("buildAndDeploy") {
        return slurp
            |> Pod.Install()
            |> Version(.incrementBuildNumber, all: true)
            |> Version(.setMarketingVersion("1.0.1"), all: true)
            |> XcodeBuild([.archive, .export], config: xcBuildConfig)
            |> ApplicationLoader(.uploadApp, config: uploadConfig)
    }

try! slurp.runAndExit(taskName: "buildAndDeploy")

```

### Monitoring the filesystem for changes, then running tasks
This is useful for development workflows that involve files generated from 3rd party tools (e.g. graphics editors). If you are looking for ways to develop in Swift without using Xcode, this may be useful for running tests and linters automatically also. 

```swift
import Slurp

let slurp = Slurp()
slurp.watch(paths: ["Tests/**.swift"], recursive: true)
.flatMap { _ in
  return try! slurp.run(taskName: "runTests")
}
.subscribe(onError: { err in
  print(err)
})

RunLoop.main.run() // Keep the task running indefinitely
```

## Installation
Add Slurp to your `package.swift` and create a new executable `Tasks` module with Slurp as a dependency. You may also need `SlurpXCTools` for Xcode related Tasks.
A basic `package.swift` might look like this:

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    products: [],
    dependencies: [
      .package(url: "https://github.com/bitwit/Slurp.git", .exact(.init(0, 0, 1))),
    ],
    targets: [
        .target(
            name: "Tasks",
            dependencies: ["Slurp", "SlurpXCTools"])
    ]
)
```

A basic `Sources/Tasks/main.swift` file would look like:

```swift
import Slurp

let slurp = Slurp()

slurp.register("sayHello", Shell(arguments: ["echo", "hello world"]))

try! slurp.runAndExit(taskName: "sayHello")
```

From the command line you can now execute: 

```sh
$ swift run Tasks
```

### Developing and Running in Xcode
Start by setting up a workspace. Then run

 ```sh
 $ swift package generate-xcodeproj --output myTasks.xcodeproj
 ```
 > **Note**: By default the xcodeproj file name is your Package name i.e. "MyApp.xcodeproj". Keep this generated xcodeproj separate from your main XCode target app so that can can rerun this command if necessary
 
 Include this xcodeproj in your workspace. There should now be a scheme you can run to execute your task. You may need set your current working directory in order for this to run processes from the right folder.
 
```swift
Slurp.currentWorkingDirectory = "/path/to/app"
```
> **Note**: You can pass this as an environment variable too through `SLURP_CWD`. This can be set in your task scheme's configuration

This git repo contains an xcworkspace and example app that mimic this suggested structure.

## Currently Available Tasks
- Shell
- Xcodebuild (`xcodebuild`)
- Version (`agvtool`)
- ApplicationLoader (`altool`)
- Cocoapods (`pod`)

## Writing your own task
There are 3 ways to build your own task:

1. Simply register an RxSwift Observable

    ```swift
    let myTaskObservable: Observable<Int> = Observable.create { observer in
    	observer.onNext(100)
    	observer.onCompleted()
    	return Disposables.create()
    }
    
    slurp
    .register("myTask") {
        return myTaskObservable
    }
    ```

2. Use the `BasicTask` class either directly or through inheritance. It can be initialized with either an RxSwift Observable or a callback function with a `(Error?, T?) -> Void` method signature

    ```swift
    open class BasicTask<T>: SlurpTask {
  
      public init(observable: Observable<T>)
    
      public convenience init(asyncTask: @escaping ( (Error?, T?) -> Void ) -> Void) 
    }
    ```

3. Make your class conform to the `SlurpTask` protocol:

    ```swift
    public protocol SlurpTask {
   
        associatedtype OutputType
    
        func onPipe<U>(from input: U) -> Observable<OutputType>
    }
    ```
> **Note:** `onPipe<U>`'s generic format is mostly there for posterity since all current tasks do not consume from the previous task's output. This may change in the future, particularly for file system management tasks

Options 2 & 3, which involve conforming to `SlurpTask`, are eligible for piping to and from other tasks.

## The Pipe Operator
For convenience and cleanliness Slurp uses the pipe operator i.e `|>`. This is a substitute for calling `func pipe(to: SlurpTask)`. 

```swift
return slurp
            |> XcodeBuild([.archive, .export], config: xcBuildConfig)
            |> ApplicationLoader(.uploadApp, config: uploadConfig)
```
Is equivalent to

```swift
return slurp
            .pipe(to: XcodeBuild([.archive, .export], config: xcBuildConfig))
            .pipe(to: ApplicationLoader(.uploadApp, config: uploadConfig))
```

## Roadmap
Some future desires/plans. Requests and contributions very welcome!

- Solidify API
- Slurp CLI
- Dry run flag
- Prettier output
- Improve Xcode integration flow
- Make more tasks. Personal wish list:
	- Swiftlint task
	- Slack API task
	- File system tasks
	- AWS S3 Management
	- AWS Cloudfront
	- Download Dsyms
	- Upload Dsyms to New Relic (and others)

## Feedback
Feel free to [open an issue](https://github.com/bitwit/Slurp/issues/new) or [find me on twitter](http://www.twitter.com/kylnew)
