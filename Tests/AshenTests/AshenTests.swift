////
///  main.swift
//

import XCTest
@testable import Ashen

class TodoTests: XCTestCase {
    func testAshen() {
        let app = App(program: SpecsProgram(verbose: false), screen: SpecsScreen())
        XCTAssertNoThrow(try app.run())
    }
}
