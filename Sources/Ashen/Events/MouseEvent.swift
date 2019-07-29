////
///  MouseEvent.swift
//

public struct MouseEvent {
    public let x: Int16
    public let y: Int16
    public let event: Event

    public enum Event {
        case click(Button)
        case scroll(Direction)
        case release
    }

    public enum Button {
        case left
        case middle
        case right
    }

    public enum Direction {
        case up
        case down
    }

}

public extension MouseEvent {
    var toString: String {
        switch self.event {
        case .release:
            return "release((\(x), \(y), )"
        case let .click(btn):
            return "click((\(x), \(y), \(btn))"
        case let .scroll(direction):
            return "scroll((\(x), \(y), \(direction))"
        }
    }
}

extension MouseEvent: Equatable {
    public static func == (lhs: MouseEvent, rhs: MouseEvent) -> Bool {
        return lhs.toString == rhs.toString
    }
}
