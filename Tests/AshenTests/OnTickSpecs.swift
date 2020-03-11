////
///  OnTickSpecs.swift
//

@testable import Ashen

struct OnTickSpecs: Spec {
    var name: String { "OnTickSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let screen = MockScreen()
        var program = MockProgram()
        var ticked = false
        var dt: Float = 0
        program.component = OnTick({ tickDt in
            dt = tickDt
            ticked = true
            return MockProgram.Quit()
        })
        let app = App(program: program, screen: screen)
        _ = app.run()
        expect("receives .tick (\(ticked))").assert(ticked)
        expect("dt(\(dt)) is reasonable").assert(dt > 0.001)
        done()
    }
}
