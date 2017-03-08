////
///  LabelViewSpecs.swift
//


struct LabelViewSpecs: Spec {
    var name: String { return "LabelViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = LabelView(.topLeft(), text: "test")
        let buffer = subject.render(size: Size.max)
        expect("outputs 'test'").assert(SpecsProgram.toString(buffer) == "test")
        done()
    }
}
