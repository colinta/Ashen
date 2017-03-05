////
///  Specs.swift
//

import Foundation


private let specs: [SpecRunner] = [
    InputViewSpecs(),
    LabelViewSpecs(),
    OnNextSpecs(),
    OnTickSpecs(),
    ScreenSpecs(),
    SizeDescriptionSpecs(),
    SpinnerViewSpecs(),
    WindowSpecs(),
]


struct Specs: Program {
    struct SpecsModel {
        var passed: Int = 0
        var failed: Int = 0
        var specRunners: [SpecRunner]
        var running = false
        var done = false
        var specLog: [String]

        init(_ specRunners: [SpecRunner]) {
            self.specRunners = specRunners
            specLog = ["Begin."]
        }
    }

    enum SpecsMessage {
        case begin
        case quit
        case specLog(String)
        case expectations(Int, Int)
    }

    enum SpecsCommand {
        case spec(SpecRunner)
    }

    let onEnd: LoopState

    init(onEnd: LoopState) {
        self.onEnd = onEnd
    }

    func initial() -> (SpecsModel, [SpecsCommand]) {
        return (SpecsModel(specs), [])
    }

    func update(model: inout SpecsModel, message: SpecsMessage)
        -> (SpecsModel, [SpecsCommand], LoopState)
    {
        var runNext = false
        switch message {
        case .quit:
            return (model, [], .quit)
        case .begin:
            model.running = true
            runNext = true
            startTimer()
        case let .specLog(specName):
            model.specLog.append(specName)
        case let .expectations(passed, failed):
            model.passed += passed
            model.failed += failed
            runNext = true
        }

        if runNext {
            if model.specRunners.count == 0 {
                model.done = true
                model.specLog.append("")
                model.specLog.append("Completed \(specs.count) runs in \(stopTimer())")
                model.specLog.append("\(model.passed) passed \(model.failed) failed")
            }
            else {
                let runner = model.specRunners.removeFirst()
                model.specLog.append("--- \(runner.name) ---")
                return (model, [.spec(runner)], .continue)
            }
        }
        return (model, [], .continue)
    }

    func render(model: SpecsModel, in screenSize: Size) -> Component {
        var components: [Component] = []

        if model.done {
            if onEnd == .quit {
                components.append(OnNext({ return SpecsMessage.quit }))
            }
            else {
                components.append(OnKeyPress({ _ in return SpecsMessage.quit }))
            }
        }

        components.append(LogView(y: 4, entries: model.specLog, screenSize: screenSize))
        if !model.running {
            components.append(OnNext({ SpecsMessage.begin }))
        }
        return Window(components: components)
    }

    func start(command: SpecsCommand, done: @escaping (SpecsMessage) -> Void) {
        if case let .spec(specRunner) = command {
            let expectations = Expectations()
            let generator: (String) -> Expectations = { desc in
                return expectations.describe(desc)
            }
            specRunner.run(expect: generator) {
                expectations.commit()
                for message in expectations.messages {
                    done(SpecsMessage.specLog("\(message)"))
                }
                done(SpecsMessage.expectations(expectations.totalPassed, expectations.totalFailed))
            }
        }
    }
}

extension Specs {
    static func toString(_ chars: [Int: [Int: TextType]]) -> String {
        var output = ""
        let lines = chars
            .map { y, line in return (y, line) }
            .sorted { a, b in return a.0 < b.0 }
            .map { _, line in return line }
        for line in lines {
            if output != "" {
                output += "\n"
            }

            var prevX = line.max { a, b in return a.0 > b.0 }!.0
            let text = line
                .map { x, c in
                    return (x, c)
                }
                .sorted { a, b in return a.0 < b.0 }
            for (x, c) in text {
                while prevX < x {
                    output += " "
                    prevX += 1
                }
                output += c.text
                prevX += 1
            }
        }

        return output
    }
}

private var t0: Int?
private func startTimer() {
    t0 = Int(mach_absolute_time())
}

private func stopTimer() -> String {
    let start: Int = t0!
    let now = Int(mach_absolute_time())

    return "\((now - start) / 1_000_000)ms"
}
