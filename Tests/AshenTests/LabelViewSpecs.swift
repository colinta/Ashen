////
///  LabelViewSpecs.swift
//

@testable import Ashen

struct LabelViewSpecs: Spec {
    var name: String { "LabelViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = LabelView(at: .topLeft(), text: "test")
        expect("outputs 'test'").assertRenders(subject, "test")
        done()
    }
}
