////
///  OnTickSpecs.swift
//


class OnTickSpecs: SpecRunner {
    override var name: String { return "OnTickSpecs" }

    override func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let screen = MockScreen()
        let program = MockProgram()
        let app = App(program: program, screen: screen)
        var ticked = false
        var dt: Float = 0
        program.component = OnTick({ tickDt in
            dt = tickDt
            ticked = true
            return MockProgram.Quit()
        })
        _ = app.run()
        expect("receives .tick (\(ticked))").assert(ticked)
        expect("dt(\(dt)) is reasonable").assert(dt > 0.01)
        done()
    }
}
