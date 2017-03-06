////
///  LabelViewSpecs.swift
//


class LabelViewSpecs: SpecRunner {
    override var name: String { return "LabelViewSpecs" }

    override func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = LabelView(.topLeft(), text: "test")
        expect("outputs 'test'").assert(Specs.toString(subject.chars(in: Size.max)) == "test")
        done()
    }
}
