import Foundation
import RxSwift
import PathKit

public class Watcher {
    
    fileprivate var monitors: [FolderMonitor] = []
    fileprivate var eventPublishSubject: PublishSubject<Void> = PublishSubject()
    
    public init(globs: [String], recursive: Bool = false) {
        
        let pathsToWatch = globs
            .flatMap { path -> [Path] in
                var cleanPath = path
                if cleanPath.starts(with: "./") {
                    cleanPath.removeFirst(2)
                }
                guard let pathWithoutExt = cleanPath.components(separatedBy: ".").first else {
                    return []
                }
                
                return Path.glob(pathWithoutExt)
                    .flatMap { path -> [Path] in
                        var paths = [path]
                        if recursive
                            , let recursivePaths = try? path.recursiveChildren() {
                            paths.append(contentsOf: recursivePaths)
                        }
                        return paths
                }
            }
            .filter { $0.isDirectory }
        
        print("Paths to watch: ", pathsToWatch)
        let monitor = FolderMonitor(paths: pathsToWatch, globs: globs, handler: { [weak self] in
            self?.eventPublishSubject.onNext(())
        })
        monitors.append(monitor)
    }
    
    deinit {
        print("Watcher deinit")
    }
    
    public func asObservable() -> Observable<Void> {
        return eventPublishSubject
    }
    
}
