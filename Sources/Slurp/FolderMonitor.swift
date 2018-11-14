import Foundation
import PathKit
import CoreServices

enum FSEvent {
    
    case fileCreated
    case fileModified
    case fileRemoved
    case fileRenamed
    case other
    
    static func fromFlag(_ f: UInt32) -> FSEvent {
        
        let flag = Int(f)
        let isTempChange = (kFSEventStreamEventFlagItemIsFile | kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemChangeOwner)
        let isTempFileMod = (kFSEventStreamEventFlagItemIsFile | kFSEventStreamEventFlagItemRenamed | kFSEventStreamEventFlagItemRemoved)
        let isFileModified = (kFSEventStreamEventFlagItemIsFile | kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemModified)
        let isFileCreated = (kFSEventStreamEventFlagItemIsFile | kFSEventStreamEventFlagItemCreated)
        let isFileRemoved = (kFSEventStreamEventFlagItemIsFile | kFSEventStreamEventFlagItemRemoved)
        let isFileRenamed = (kFSEventStreamEventFlagItemIsFile | kFSEventStreamEventFlagItemRenamed)

        if flag == isFileCreated {
            return .fileCreated
        }
        else if flag & isFileModified == isFileModified {
            return .fileModified
        }
        else if flag & isFileRenamed == isFileRenamed {
            return .fileRenamed
        }
        else if flag & isFileRemoved == isFileRemoved {
            return .fileRemoved
        }
        
        return .other
    }
    
}

public class FolderMonitor {
    
    enum State {
        case on, off
    }
    
    let handler: () -> Void
    let globs: [String]
    
    public init(paths: [Path], globs: [String], handler: @escaping () -> Void) {
        
        self.handler = handler
        self.globs = globs

        let pathsToWatch: [CFString] = paths.map { $0.string as CFString }
        let latency: CFAbsoluteTime = 0.5
        let info = Unmanaged.passRetained(self).toOpaque()
        
        let callback: FSEventStreamCallback = { (eventStreamRef, callbackInfo, numEvents, paths, flags, ids) in
            
            guard let info = callbackInfo else {
                fatalError("Could not access callback info")
            }
            
            guard let paths = unsafeBitCast(paths, to: NSArray.self) as? [String] else {
                return
            }
            
            let fsEvents = Array(UnsafeBufferPointer(start: flags, count: numEvents)).map { FSEvent.fromFlag($0) }
            let eventIDs = Array(UnsafeBufferPointer(start: ids, count: numEvents))
            let cwd = FileManager.default.currentDirectoryPath + "/"
            
            var events: [(Path, FSEvent)] = []
            for i in 0..<numEvents {
                let path = Path(paths[i].replacingOccurrences(of: cwd, with: ""))
                events.append((path, fsEvents[i]))
            }
            
            let monitor = Unmanaged<FolderMonitor>.fromOpaque(info).takeUnretainedValue()
            monitor.onChange(events: events)
        }
        
        var context = FSEventStreamContext.init()
        context.version = 0
        context.info = info

        guard let streamRef = FSEventStreamCreate(nil,
                                                  callback,
                                                  &context,
                                                  pathsToWatch as CFArray,
                                                  FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                                  latency,
                                                  UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagWatchRoot)
            ) else {
            fatalError("Could not open stream for \(paths)")
        }
        
        FSEventStreamScheduleWithRunLoop(streamRef, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(streamRef)
        
        print("Created stream for", paths)
    }
    
    func onChange(events: [(Path, FSEvent)]) {
        
        let validEvents = events.filter { FolderMonitor.filename(Path($0.0.string).absolute().string, matchesAnyGlob: globs) }
        if false == validEvents.isEmpty {
            print(validEvents)
            handler()
        }
    }
    
    static func globToRegex(_ globString: String) -> String {
        var regexString = globString
        regexString = regexString.replacingOccurrences(of: "./", with: "") // remove relative dir prefix
        regexString = regexString.replacingOccurrences(of: ".", with: "\\.") // escape periods
        regexString = regexString.replacingOccurrences(of: "**", with: ".*") // convert glob ** to regex
        regexString = regexString.replacingOccurrences(of: "*", with: ".*") // convert glob * to regex
        regexString += "$" // expect end of line
        return regexString
    }
    
    static func filename(_ filename: String, matchesGlob glob: String) -> Bool {
        let pattern = try? NSRegularExpression(pattern: globToRegex(glob), options: [])
        return nil != pattern?.firstMatch(in: filename, options: [], range: NSRange(location: 0, length: filename.count))
    }
    
    static func filename(_ filename: String, matchesAnyGlob globs: [String]) -> Bool {
        return globs.contains { FolderMonitor.filename(filename, matchesGlob: $0) }
    }

    
    /// Starts sending notifications if currently stopped
    public func start() {
//        if state == .off {
//            state = .on
//            source.resume()
//        }
    }
    
    /// Stops sending notifications if currently enabled
    public func stop() {
//        if state == .on {
//            state = .off
//            source.suspend()
//        }
    }
    
    deinit {
        print("fodler monitor deinit")
//        close(descriptor)
//        source.cancel()
    }
}
