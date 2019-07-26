////
///  EscapeSequence.swift
//

import Termbox

struct EscapeSequence {
    let matchEvent: ([TermboxEvent]) -> KeyEvent
    let matchesTest: ([TermboxEvent]) -> Bool

    init(_ matchEvent: KeyEvent, _ matchesGenerator: @escaping () -> String) {
        self.init({ _ in return matchEvent}, { events in
            let literal = matchesGenerator()
            return matchLiterals(events, literal)
        })
    }

    init(_ matchEvent: @escaping ([TermboxEvent]) -> KeyEvent, _ matchesGenerator: @escaping ([TermboxEvent]) -> Bool) {
        self.matchEvent = matchEvent
        self.matchesTest = matchesGenerator
    }

    func match(_ events: [TermboxEvent]) -> Event? {
        guard self.matchesTest(events) else { return nil }
        return .key(matchEvent(events))
    }

}

private func matchLiterals(_ events: [TermboxEvent], _ matches: String) -> Bool {
    guard events.count == matches.count else { return false }

    for (event, match) in zip(events, matches) {
        switch (event, match) {
        case let (.character(_, eventValue), matchValue):
            if eventValue != matchValue.unicodeScalars.first! { return false }
        default:
            return false
        }
    }
    return true
}
