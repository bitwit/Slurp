import Foundation
import Slurp
import PathKit

public class Pod {

    public class Install: Shell {

        public struct Config {

          var repoUpdate: Bool = false
          var projectDirectory: String?
          var silent: Bool = false
          var verbose: Bool = false
          var noAnsi: Bool = false
          public init() {}
        }

        public init(_ config: Config = Config()) {
            var arguments = ["pod", "install"]

            if config.repoUpdate {
              arguments += ["--repo-update"]
            }

            if let projDir = config.projectDirectory {
              arguments += ["--project-directory=\(Path(projDir).absolute())"]
            }

            if config.silent {
              arguments += ["--silent"]
            }

            if config.verbose {
              arguments += ["--verbose"]
            }

            if config.noAnsi {
              arguments += ["--no-ansi"]
            }

            super.init(arguments: arguments)
        }
    }

    public class Update: Shell {

        public struct Config {

          var sources: String?
          var projectDirectory: String?
          var noRepoUpdate: Bool = false
          var silent: Bool = false
          var verbose: Bool = false
          var noAnsi: Bool = false

          public init() {}
        }

        public init(_ config: Config = Config()) {
            var arguments = ["pod", "update"]

            if let sources = config.sources {
              arguments += ["--sources=\(sources)"]
            }

            if let projDir = config.projectDirectory {
              arguments += ["--project-directory=\(Path(projDir).absolute())"]
            }

            if config.noRepoUpdate {
              arguments += ["--no-repo-update"]
            }

            if config.silent {
              arguments += ["--silent"]
            }

            if config.verbose {
              arguments += ["--verbose"]
            }

            if config.noAnsi {
              arguments += ["--no-ansi"]
            }

            super.init(arguments: arguments)
        }
    }
}
