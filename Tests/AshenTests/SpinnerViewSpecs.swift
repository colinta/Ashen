////
///  SpinnerViewSpecs.swift
//

@testable import Ashen

struct SpinnerViewSpecs: Spec {
    var name: String { return "SpinnerViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = SpinnerView(
            .topLeft(),
            model: SpinnerView.Model(
                spinner: ["a", "b", "c"]
                ))
        subject.timeout = -1
        let size = Size(width: 1, height: 1)
        let bufferA = subject.render(size: size)
        expect("outputs 'a'").assert(SpecsProgram.toString(bufferA) == "a")
        _ = subject.messages(for: .tick(0))
        let bufferB = subject.render(size: size)
        expect("outputs 'b'").assert(SpecsProgram.toString(bufferB) == "b")
        done()
    }
}
