////
///  SpecRunner.swift
//


class SpecRunner: Command {
    var name: String { return "" }

    override func start(_ done: @escaping (AnyMessage) -> Void) {
        let expectations = Expectations()
        let generator: (String) -> Expectations = { desc in
            return expectations.describe(desc)
        }

        run(expect: generator) {
            expectations.commit()
            for message in expectations.messages {
                done(Specs.SpecsMessage.specLog("\(message)"))
            }
            done(Specs.SpecsMessage.expectations(expectations.totalPassed, expectations.totalFailed))
        }
    }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        fatalError("you should override this")
    }
}
