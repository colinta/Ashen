////
///  Expectations.swift
//

class Expectations {
    var description: String?
    private var passed = 0
    private var failed = 0
    var totalPassed: Int = 0
    var totalFailed: Int = 0
    var messages: [String] = []

    func commit() {
        totalPassed += passed
        totalFailed += failed

        if let description = description, passed + failed > 0 {
            if failed == 0 {
                messages.append(" ✓ \(description)")
            }
            else {
                messages.append(" ✘ \(description)" + (passed + failed == 1 ? "" : " \(passed)/\(passed + failed)"))
            }
        }
        passed = 0
        failed = 0
        description = nil
    }

    func describe(_ newDescription: String) -> Self {
        commit()
        description = newDescription
        return self
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

        if let description = description, !isEqual {
            let lhsDesc: String = lhs.map { "\($0)" } ?? "nil"
            let rhsDesc: String = rhs.map { "\($0)" } ?? "nil"
            self.description = "\(description) (" + (addlDescription == "" ? "" : "\(addlDescription): ") + "\(lhsDesc) != \(rhsDesc))"
        }
        assert(isEqual)
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

        return self
    }

    func refute(_ values: Bool...) -> Self {
        for value in values {
            assert(!value)
        }
        return self
    }
}
