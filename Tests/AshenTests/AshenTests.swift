////
///  main.swift
//

import XCTest
@testable import Ashen

class BasicTests: XCTestCase {
    func testAshen() {
        XCTAssertNoThrow(
            try Ashen(Program({ Initial(1) }, { _, _ in 1 }, { _, _ in Text("") }
            )))
    }
}
