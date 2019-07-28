////
///  main.swift
//

import XCTest
@testable import Ashen

class TodoTests: XCTestCase {
    func testAshen() {
        let app = App(program: SpecsProgram(verbose: false, onEnd: .quit), screen: SpecsScreen())
        let state = app.run()

        XCTAssertEqual(state, AppState.quit, "See log for details")
    }
}
