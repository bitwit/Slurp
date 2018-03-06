![Slurp Logo](https://raw.githubusercontent.com/bitwit/Slurp/master/slurp-logo.jpg)

[![Build Status](https://www.bitrise.io/app/000a61c8091db1a1/status.svg?token=HJjORiUavGh7lyVYVx794g)](https://www.bitrise.io/app/000a61c8091db1a1)
[![Swift Package Manager Compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Releases](https://img.shields.io/github/tag/bitwit/slurp.svg)](https://github.com/bitwit/Slurp/releases)


A Swift task runner and file watcher that you can run from your Xcode Workspace or the ommand line. Comes with everything you need to build and deploy an iOS app just by running an XCode Scheme. 
Inspired by Gulp.js. 

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

1. `$ git clone git@github.com:bitwit/Slurp.git`
2. `$ cd Slurp && make`
3. The Slurp CLI will now be installed and the repo copied to `~/.slurp/clone` for local reference in your projects

## Adding Slurp to your project
In the root of the project:
1. `$ slurp init`. This will create a new SlurpTasks package in `<project root>/Slurp`.
2. `$ slurp edit` will open the the SlurpTasks Xcode project, but you can also add this project to your regular Workspace.
3. `$ slurp` will run your SlurpTasks executable

## Your first slurp task

A basic `Sources/SlurpTasks/main.swift` file would look like:

```swift
import Slurp

let slurp = Slurp()

slurp.register("sayHello", Shell(arguments: ["echo", "hello world"]))

try! slurp.runAndExit(taskName: "sayHello")
```

### Developing and Running in Xcode

When you run your Tasks from XCode it will execute from the build folder. To get around this there are several ways to set the current working directly correctly:

1. Set it at the top of your main.swift

```swift
Slurp.currentWorkingDirectory = "/path/to/app"
```
2. Pass it as an environment variable

`$ SLURP_CWD=/path/to/app slurp`

3. Change it at any point in the task flow
```swift
slurp
    .register("example") {
        return slurp
            |> CWD("~/Development/personal/Slurp")
            |> ...
    }
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
