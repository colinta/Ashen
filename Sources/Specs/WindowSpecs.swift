////
///  WindowSpecs.swift
//


struct WindowSpecs: SpecRunner {
    let name = "WindowSpecs"

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let spinnerA = SpinnerView(.topLeft(), model: nil)
        spinnerA.index = 1
        let spinnerB = SpinnerView(.topLeft(), model: nil)
        spinnerB.index = 2
        let prevWindow = Window(components: [
            spinnerA,
            spinnerB,
        ])
        let subject = Window(components: [
            LabelView(.topLeft(), text: ""),
            SpinnerView(.topLeft(), model: nil),
            LabelView(.topLeft(), text: ""),
            SpinnerView(.topLeft(), model: nil),
            LabelView(.topLeft(), text: ""),
        ])
        subject.merge(with: prevWindow)
        let spinnerAFinal = subject.components[1] as! SpinnerView
        let spinnerBFinal = subject.components[3] as! SpinnerView
        expect("spinnerA updates index").assertEqual(spinnerA.index ?? -1, spinnerAFinal.index ?? -1)
        expect("spinnerB updates index").assertEqual(spinnerB.index ?? -1, spinnerBFinal.index ?? -1)
        done()
    }
}
