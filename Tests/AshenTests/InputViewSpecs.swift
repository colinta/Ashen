////
///  InputViewSpecs.swift
//

@testable import Ashen

struct InputViewSpecs: Spec {
    var name: String { return "InputViewSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        withText(expect, "test", startingAt: (3, 0), pressing: .underscore, goesTo: (4, 0), "tes_t")
        withText(expect, "test", startingAt: (4, 0), pressing: .backspace, goesTo: (3, 0), "tes")
        withText(expect, "test", startingAt: (0, 0), pressing: .backspace, goesTo: (0, 0))
        withText(expect, "test", startingAt: (1, 2), pressing: .backspace, goesTo: (1, 0), "tt")
        withText(expect, "test", startingAt: (3, 0), pressing: .left, goesTo: (2, 0))
        withText(expect, "test", startingAt: (4, -3), pressing: .left, goesTo: (1, 0))
        withText(expect, "test", startingAt: (3, 0), pressing: .shift(.left), goesTo: (3, -1))
        withText(expect, "test", startingAt: (3, 0), pressing: .right, goesTo: (4, 0))
        withText(expect, "test", startingAt: (1, 3), pressing: .right, goesTo: (4, 0))
        withText(expect, "test", startingAt: (3, 0), pressing: .shift(.right), goesTo: (3, 1))
        withText(expect, "test", startingAt: (3, 0), pressing: .ctrl(.a), goesTo: (0, 0))
        withText(expect, "test", startingAt: (1, 3), pressing: .ctrl(.a), goesTo: (0, 0))
        withText(expect, "test", startingAt: (3, 0), pressing: .ctrl(.e), goesTo: (4, 0))
        withText(expect, "test", startingAt: (3, -2), pressing: .ctrl(.e), goesTo: (4, 0))

        withText(expect, "12345\n1234567\n1234", startingAt: (4, 0), pressing: .up, goesTo: (0, 0))
        withText(expect, "12345\n1234567\n1234", startingAt: (14, 4), pressing: .up, goesTo: (10, 0))
        withText(expect, "1\n", startingAt: (2, 0), pressing: .up, goesTo: (0, 0))
        withText(expect, "12345\n1234567", startingAt: (8, 0), pressing: .shift(.up), goesTo: (8, -6))
        withText(expect, "12345\n1234567", startingAt: (8, -6), pressing: .shift(.up), goesTo: (8, -8))
        withText(expect, "12345\n1234567", startingAt: (13, 0), pressing: .shift(.up), goesTo: (13, -8))

        withText(expect, "1234567\n12345\n1234", startingAt: (2, -2), pressing: .down, goesTo: (8, 0))
        withText(expect, "1234567\n12345\n1234", startingAt: (7, 0), pressing: .down, goesTo: (13, 0))
        withText(expect, "1234567\n12345\n1234", startingAt: (15, 0), pressing: .down, goesTo: (18, 0))
        withText(expect, "12345\n12345678901234567890", startingAt: (0, 6), pressing: .shift(.down), goesTo: (0, 26))
        withText(expect, "12345\n12345678901234567890", startingAt: (6, 0), pressing: .shift(.down), goesTo: (6, 20))
        done()
    }

    func withText(
        _ expect: (String) -> Expectations,
        _ startingText: String,
        startingAt startingCursor: (Int, Int),
        pressing keyEvent: KeyEvent,
        goesTo finalCursor: (Int, Int),
        _ finalText: String? = nil)
    {
        let text = startingText
        var changedText: String?
        let subject = InputView(
            at: .topLeft(),
            text: text,
            isFirstResponder: true,
            onChange: { text in
                changedText = text
                return ""
            })
        subject.cursor = InputView.Cursor(at: startingCursor.0, selection: startingCursor.1)

        _ = subject.messages(for: Event.key(keyEvent))
        let newText = changedText ?? text
        var description =
            "with text \"\(startingText.replacingOccurrences(of: "\n", with: "\\n"))\" at \(startingCursor)," +
            " pressing \(keyEvent.toString)" +
            " goes to \(finalCursor)"
        if let finalText = finalText {
            description += " and text is \"\(finalText.replacingOccurrences(of: "\n", with: "\\n"))\""
        }
        let expectation = expect(description)
            .assertEqual(subject.cursor.at, finalCursor.0, "cursor.at")
            .assertEqual(subject.cursor.selection, finalCursor.1, "cursor.selection")
        if let finalText = finalText {
            expectation.assertEqual(newText, finalText, "text")
        }
    }

}
