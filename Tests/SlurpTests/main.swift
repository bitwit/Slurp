import Quick
import Nimble
import RxSwift
@testable import Slurp

class ShellTaskSpec: QuickSpec {

  override func spec() {

    describe("Shell Task") {

      beforeEach {
        Slurp.processType = MockShellProcess.self
      }

      it("should prepare the shell but not initialze a process") {
        _ = Shell(arguments: ["echo", "hello world"])
        let process = MockShellProcess.lastInitializedProcess

        expect(process).to(beNil())
      }

      it("should create a process when piped to and subscribed") {
        let shell = Shell(arguments: ["echo", "hello world"])
        let disposeBag = DisposeBag()
        shell
          .onPipe(from: ())
          .subscribe(onNext: { _ in })
          .disposed(by: disposeBag)

        let process = MockShellProcess.lastInitializedProcess

        expect(process).notTo(beNil())
        expect(process?.arguments) == ["echo", "hello world"]
      }

      it("should call onNext on the observer after terminationBlock is called") {
        let shell = Shell(arguments: ["echo", "hello world"])
        var didCallOnNext = false
        let disposeBag = DisposeBag()
        shell
          .onPipe(from: ())
          .subscribe(onNext: { _ in
            didCallOnNext = true
          })
          .disposed(by: disposeBag)

        let process = MockShellProcess.lastInitializedProcess!
        process.terminationBlock?(process)

        expect(didCallOnNext) == true
      }

      it("should call onError on the observer after terminationBlock is called with a non-zero code") {
        let shell = Shell(arguments: ["echo", "hello world"])
        var didCallOnError = false
        let disposeBag = DisposeBag()
        shell
          .onPipe(from: ())
          .subscribe(onError: { _ in
            didCallOnError = true
          })
          .disposed(by: disposeBag)

        let process = MockShellProcess.lastInitializedProcess!
        process.terminationStatus = 123
        process.terminationBlock?(process)

        expect(didCallOnError) == true
      }

    }

  }

}
