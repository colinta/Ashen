////
///  SpinnerViewSpecs.swift
//

@testable import Ashen

struct SpinnerViewSpecs: Spec {
    var name: String { return "SpinnerViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = SpinnerView(
            at: .topLeft(),
            model: SpinnerView.Model(
                spinner: ["a", "b", "c"]
                ))
        subject.timeout = -1
        expect("outputs 'a'").assertRenders(subject, "a")
        _ = subject.messages(for: .tick(0))
        expect("outputs 'b'").assertRenders(subject, "b")
        done()
    }
}
