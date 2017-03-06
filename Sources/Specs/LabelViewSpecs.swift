////
///  LabelViewSpecs.swift
//


struct LabelViewSpecs: SpecRunner {
    var name: String { return "LabelViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = LabelView(.topLeft(), text: "test")
        expect("outputs 'test'").assert(Specs.toString(subject.chars(in: Size.max)) == "test")
        done()
    }
}
