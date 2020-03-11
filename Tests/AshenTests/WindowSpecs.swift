////
///  WindowSpecs.swift
//

@testable import Ashen

struct WindowSpecs: Spec {
    var name: String { "WindowSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let spinnerA = SpinnerView(at: .topLeft())
        spinnerA.index = 1
        let spinnerB = SpinnerView(at: .topLeft())
        spinnerB.index = 2
        let prevWindow = Window(components: [
            spinnerA,
            spinnerB,
        ])
        let subject = Window(components: [
            LabelView(at: .topLeft(), text: ""),
            SpinnerView(at: .topLeft()),
            LabelView(at: .topLeft(), text: ""),
            SpinnerView(at: .topLeft()),
            LabelView(at: .topLeft(), text: ""),
        ])
        subject.merge(with: prevWindow)
        let spinnerAFinal = subject.components[1] as! SpinnerView
        let spinnerBFinal = subject.components[3] as! SpinnerView
        expect("spinnerA updates index").assertEqual(
            spinnerA.index ?? -1,
            spinnerAFinal.index ?? -1
        )
        expect("spinnerB updates index").assertEqual(
            spinnerB.index ?? -1,
            spinnerBFinal.index ?? -1
        )
        done()
    }
}
