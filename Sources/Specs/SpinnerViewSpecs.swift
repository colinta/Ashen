////
///  SpinnerViewSpecs.swift
//


struct SpinnerViewSpecs: SpecRunner {
    let name = "SpinnerViewSpecs"

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let subject = SpinnerView(
            .topLeft(),
            model: SpinnerView.Model(
                spinner: ["a", "b", "c"]
                ))
        subject.timeout = -1
        let size = Size(width: 1, height: 1)
        expect("outputs 'a'").assert(Specs.toString(subject.chars(in: size)) == "a")
        _ = subject.messages(for: .tick(0))
        expect("outputs 'b'").assert(Specs.toString(subject.chars(in: size)) == "b")
        done()
    }
}
