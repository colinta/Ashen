////
///  LabelViewSpecs.swift
//


struct LabelViewSpecs: Spec {
    var name: String { return "LabelViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = LabelView(.topLeft(), text: "test")
        expect("outputs 'test'").assert(SpecsProgram.toString(subject.chars(in: Size.max)) == "test")
        done()
    }
}
