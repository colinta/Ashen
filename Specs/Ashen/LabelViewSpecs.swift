////
///  LabelViewSpecs.swift
//


struct LabelViewSpecs: Spec {
    var name: String { return "LabelViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = LabelView(.topLeft(), text: "test")
        expect("outputs 'test'").assertRenders(subject, "test")
        done()
    }
}
