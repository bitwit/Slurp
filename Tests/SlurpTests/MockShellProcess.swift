import Slurp
import Foundation

class MockShellProcess: SlurpShellProcess {

  var launchPath: String?
  var environment: [String : String]?
  var arguments: [String]?
  var terminationStatus: Int32 = 0

  var standardInput: Any?
  var standardOutput: Any?
  var standardError: Any?

  // Mock inspection
  var mockDidLaunch: Bool = false
  var mockDidTerminate: Bool = false

  var terminationBlock: ((SlurpShellProcess) -> Void)?
  var currentWorkingDirectory: String?

  static var lastInitializedProcess: MockShellProcess?

  required init() {
      MockShellProcess.lastInitializedProcess = self
  }

  func launch() {

  }

}
