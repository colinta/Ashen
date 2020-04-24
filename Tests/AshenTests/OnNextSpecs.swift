////
///  OnNextSpecs.swift
//

@testable import Ashen

struct OnNextSpecs: Spec {
    var name: String { "OnNextSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let screen = MockScreen()
        var program = MockProgram()
        var ticked = false
        program.component = OnNext({
            ticked = true
            return MockProgram.Quit()
        })
        let app = App(program: program, screen: screen)
        do {
            try app.run()
        } catch {}
        expect("receives .tick \(ticked)").assert(ticked)
        done()
    }
}
