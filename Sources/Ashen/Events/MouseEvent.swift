////
///  MouseEvent.swift
//

public struct MouseEvent {
    public let x: Int
    public let y: Int
    public let event: Event

    public var button: Button? {
        switch event {
        case let .click(button): return button
        case let .drag(button): return button
        case let .release(button): return button
        default:
            return nil
        }
    }

    public var isPressed: Bool {
        switch event {
        case .click:
            return true
        default:
            return false
        }
    }

    public var isDown: Bool {
        switch event {
        case .click, .drag:
            return true
        default:
            return false
        }
    }

    public var isReleased: Bool {
        switch event {
        case .release:
            return true
        default:
            return false
        }
    }

    public enum Event {
        case click(Button)
        case drag(Button)
        case release(Button)
        case scroll(Direction)
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

    init(x: Int, y: Int, event: Event) {
        self.x = x
        self.y = y
        self.event = event
    }
}

extension MouseEvent.Event: Equatable {
    public static func == (lhs: MouseEvent.Event, rhs: MouseEvent.Event) -> Bool {
        lhs.toString == rhs.toString
    }
}

extension MouseEvent {
    public var toString: String {
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

extension MouseEvent.Event {
    public var toString: String {
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
        lhs.toString == rhs.toString
    }
}
