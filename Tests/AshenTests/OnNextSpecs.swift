////
///  OnNextSpecs.swift
//

@testable import Ashen

struct OnNextSpecs: Spec {
    var name: String { return "OnNextSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let screen = MockScreen()
        var program = MockProgram()
        var ticked = false
        program.component = OnNext({
            ticked = true
            return MockProgram.Quit()
        })
        let app = App(program: program, screen: screen)
        _ = app.run()
        expect("receives .tick \(ticked)").assert(ticked)
        done()
    }
}
