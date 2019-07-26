////
///  EscapeSequence.swift
//

import Termbox

struct EscapeSequence {
    let matchEvent: KeyEvent
    let matchesGenerator: () -> String

    init(_ matchEvent: KeyEvent, _ matchesGenerator: @escaping () -> String) {
        self.matchEvent = matchEvent
        self.matchesGenerator = matchesGenerator
    }

    func match(_ events: [TermboxEvent]) -> Event? {
        let matches = self.matchesGenerator()

        guard events.count == matches.count else { return nil }

        for (event, match) in zip(events, matches) {
            switch (event, match) {
            case let (.character(_, eventValue), matchValue):
                if eventValue != matchValue.unicodeScalars.first! { return nil }
            default:
                return nil
            }
        }
        return .key(matchEvent)
    }
}
