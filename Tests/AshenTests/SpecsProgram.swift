////
///  SpecsProgram.swift
//

import Foundation
@testable import Ashen

private let specs: [Spec] = [
    BoxSpecs(),
    HttpSpecs(),
    InputViewSpecs(),
    LabelViewSpecs(),
    OnNextSpecs(),
    OnTickSpecs(),
    ScreenSpecs(),
    SizeDescriptionSpecs(),
    SpinnerViewSpecs(),
    WindowSpecs(),
]


struct SpecsProgram: Program {
    enum Error: Swift.Error {
        case failed
    }

    struct SpecsModel {
        var passed: Int = 0
        var failed: Int = 0
        var specs: [Spec]
        var running = false
        var done = false
        var specLog: [String]

        init(_ specs: [Spec]) {
            self.specs = specs
            specLog = ["Begin."]
        }
    }

    enum SpecsMessage {
        case begin
        case quit
        case specLog(String)
        case expectations(Int, Int)
    }

    let verbose: Bool

    init(verbose: Bool) {
        self.verbose = verbose
    }

    func initial() -> (SpecsModel, [Command]) {
        (SpecsModel(specs), [])
    }

    func update(model: inout SpecsModel, message: SpecsMessage)
        -> Update<SpecsModel>
    {
        var runNext = false
        switch message {
        case .quit:
            if model.failed > 0 {
                return .error(Error.failed)
            }
            else {
                return .quit
            }
        case .begin:
            model.running = true
            runNext = true
            startTimer()
        case let .specLog(specName):
            model.specLog.append(specName)
        case let .expectations(passed, failed):
            model.passed += passed
            model.failed += failed
            if !verbose && failed == 0 {
                model.specLog.append(" ✓ \(passed) passed")
            }
            runNext = true
        }

        if runNext {
            if model.specs.count == 0 {
                model.done = true
                model.specLog.append("")
                model.specLog.append("Completed \(specs.count) runs in \(stopTimer())ms")
                model.specLog.append("\(model.passed) passed \(model.failed) failed")
            }
            else {
                let spec = model.specs.removeFirst()
                model.specLog.append("--- \(spec.name) ---")
                let runner = SpecRunner(spec: spec, verbose: verbose)
                return .update(model, [runner])
            }
        }
        return .model(model)
    }

    func render(model: SpecsModel, in mySize: Size) -> Component {
        var components: [Component] = []

        if model.done {
            components.append(OnNext({ SpecsMessage.quit }))
        }

        components.append(LogView(at: .topLeft(y: 4), entries: model.specLog))
        if !model.running {
            components.append(OnNext({ SpecsMessage.begin }))
        }
        return Window(components: components)
    }
}

extension SpecsProgram {
    static func bufferToString(_ buffer: Buffer) -> String {
        var output = ""
        let lines = buffer.chars
            .map { y, line in (y, line) }
            .sorted { a, b in a.0 < b.0 }
            .map { _, line in line }
        for line in lines {
            if output != "" {
                output += "\n"
            }

            var prevX = (line.max(by: { a, b in a.0 > b.0 })?.0) ?? 0
            let text =
                line
                    .map { x, c in
                        (x, c)
                    }
                    .sorted { a, b in a.0 < b.0 }
            for (x, c) in text {
                while prevX < x {
                    output += " "
                    prevX += 1
                }
                if let char = c.char {
                    output += char
                }
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

private func stopTimer() -> Int {
    let start: Int = t0!
    let now = Int(mach_absolute_time())

    return (now - start) / 1_000_000
}
