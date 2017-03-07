////
///  OnNextSpecs.swift
//


struct OnNextSpecs: Spec {
    var name: String { return "OnNextSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let screen = MockScreen()
        let program = MockProgram()
        let app = App(program: program, screen: screen)
        var ticked = false
        program.component = OnNext({
            ticked = true
            return MockProgram.Quit()
        })
        _ = app.run()
        expect("receives .tick \(ticked)").assert(ticked)
        done()
    }
}
