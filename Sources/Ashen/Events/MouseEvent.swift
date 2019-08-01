////
///  MouseEvent.swift
//

public struct MouseEvent {
    public let x: Int
    public let y: Int
    public let event: Event

    public enum Event {
        case drag(Button)
        case click(Button)
        case scroll(Direction)
        case release(Button)
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
        case let .drag(btn):
            return "drag(\(x), \(y), \(btn))"
        case let .click(btn):
            return "click(\(x), \(y), \(btn))"
        case let .scroll(direction):
            return "scroll(\(x), \(y), \(direction))"
        case let .release(btn):
            return "release(\(x), \(y), \(btn))"
        }
    }
}

public extension MouseEvent.Event {
    var toString: String {
        switch self {
        case let .drag(btn):
            return "drag(\(btn))"
        case let .click(btn):
            return "click(\(btn))"
        case let .scroll(direction):
            return "scroll(\(direction))"
        case let .release(btn):
            return "release(\(btn))"
        }
    }
}

extension MouseEvent: Equatable {
    public static func == (lhs: MouseEvent, rhs: MouseEvent) -> Bool {
        return lhs.toString == rhs.toString
    }
}
