////
///  SpecRunner.swift
//

@testable import Ashen

protocol Spec {
    var name: String { get }
    func run(expect: (String) -> Expectations, done: @escaping () -> Void)
}

struct SpecRunner: Command {
    let spec: Spec
    let verbose: Bool

    init(spec: Spec, verbose: Bool) {
        self.spec = spec
        self.verbose = verbose
    }

    func start(_ done: @escaping (AnyMessage) -> Void) {
        let expectations = Expectations(showSuccess: verbose)
        let generator: (String) -> Expectations = { desc in
            return expectations.describe(desc)
        }

        spec.run(expect: generator) {
            expectations.commit()
            for message in expectations.messages {
                done(SpecsProgram.SpecsMessage.specLog("\(message)"))
            }
            done(
                SpecsProgram.SpecsMessage.expectations(
                    expectations.totalPassed,
                    expectations.totalFailed
                )
            )
        }
    }
}
