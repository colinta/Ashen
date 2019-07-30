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

extension MouseEvent.Event: Equatable {
    static public func == (lhs: MouseEvent.Event, rhs: MouseEvent.Event) -> Bool {
        return lhs.toString == rhs.toString
    }
}

public extension MouseEvent {
    var toString: String {
        switch self.event {
        case let .click(btn):
            return "click(\(x), \(y), \(btn))"
        case let .scroll(direction):
            return "scroll(\(x), \(y), \(direction))"
        case .release:
            return "release(\(x), \(y))"
        }
    }
}

public extension MouseEvent.Event {
    var toString: String {
        switch self {
        case let .click(btn):
            return "click(\(btn))"
        case let .scroll(direction):
            return "scroll(\(direction))"
        case .release:
            return "release"
        }
    }
}

extension MouseEvent: Equatable {
    public static func == (lhs: MouseEvent, rhs: MouseEvent) -> Bool {
        return lhs.toString == rhs.toString
    }
}
