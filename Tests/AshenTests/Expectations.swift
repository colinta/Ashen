////
///  Expectations.swift
//

@testable import Ashen

class Expectations {
    var originalDescription: String?
    var description: String?
    var showSuccess: Bool
    private var passed = 0
    private var failed = 0
    var totalPassed: Int = 0
    var totalFailed: Int = 0
    var messages: [String] = []

    init(showSuccess: Bool) {
        self.showSuccess = showSuccess
    }

    func commit() {
        commitNext()
        description = nil
        originalDescription = nil
    }

    func commitNext() {
        totalPassed += passed
        totalFailed += failed

        if let description = description, passed + failed > 0 {
            let totalCount = (passed + failed == 1 ? "" : " \(passed)/\(passed + failed)")
            if failed > 0 {
                messages.append(" ✘ \(description)\(totalCount)")
            }
            else if showSuccess {
                messages.append(" ✓ \(description)")
            }
        }
        passed = 0
        failed = 0
        description = originalDescription
    }

    func describe(_ newDescription: String) -> Self {
        commit()
        description = newDescription
        originalDescription = newDescription
        return self
    }

    @discardableResult
    func log(_ values: CustomStringConvertible...) -> Self {
        for val in values {
            messages.append(val.description)
        }

        return self
    }

    @discardableResult
    func assertRenders(_ lhs: ComponentView, _ rhs: String, _ addlDescription: String = "") -> Self
    {
        let viewSize = lhs.desiredSize().constrain(in: Size.max)
        let buffer = lhs.render(size: viewSize)
        let rendered = SpecsProgram.bufferToString(buffer)
        return assertEqual(rendered, rhs, addlDescription)
    }

    @discardableResult
    func assertEqual<T: Equatable>(_ lhs: T?, _ rhs: T?, _ addlDescription: String = "") -> Self {
        let isEqual: Bool
        if let lhs = lhs, let rhs = rhs {
            isEqual = lhs == rhs
        }
        else {
            isEqual = lhs == nil && rhs == nil
        }

        if !isEqual, let description = description {
            let lhsDesc: String = (lhs.map { "\"\($0)\"" } ?? "nil").replacingOccurrences(
                of: "\n",
                with: "\\n"
            )
            let rhsDesc: String = (rhs.map { "\"\($0)\"" } ?? "nil").replacingOccurrences(
                of: "\n",
                with: "\\n"
            )
            self.description = "\(description) (" + (
                addlDescription == "" ? "" : "\(addlDescription): "
            ) + "\(lhsDesc) != \(rhsDesc))"
        }
        assert(isEqual)
        return self
    }

    @discardableResult
    func refute(_ values: Bool...) -> Self {
        for value in values {
            assert(!value)
        }
        return self
    }

    @discardableResult
    func assert(_ values: Bool...) -> Self {
        for val in values {
            if val {
                passed += 1
            }
            else {
                failed += 1
            }
        }

        commitNext()
        return self
    }
}
