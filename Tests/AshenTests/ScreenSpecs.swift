////
///  ScreenSpecs.swift
//

@testable import Ashen

struct ScreenSpecs: Spec {
    var name: String { "ScreenSpecs" }
    struct ScreenModel {}

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let screen = MockScreen()
        let app = App(program: MockProgram(model: ScreenModel()), screen: screen)
        do {
            try app.run()
        } catch {}
        expect("setup called \(screen.setupCalled)x").assertEqual(screen.setupCalled, 1)
        expect("teardown called \(screen.teardownCalled)x").assertEqual(screen.teardownCalled, 1)
        done()
    }
}
