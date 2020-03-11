////
///  MouseEvent.swift
//

public struct MouseEvent {
    public let x: Int
    public let y: Int
    public let event: Event
    public let component: Component?

    public var button: Button? {
        switch event {
        case let .click(button): return button
        case let .drag(button): return button
        case let .release(button): return button
        default:
            return nil
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
        self.component = nil
    }

    init(x: Int, y: Int, event: Event, component: Component) {
        self.x = x
        self.y = y
        self.event = event
        self.component = component
    }

    func on(info: (Component, Point)) -> MouseEvent {
        MouseEvent(x: x - info.1.x, y: y - info.1.y, event: event, component: info.0)
    }

}

extension MouseEvent.Event: Equatable {
    public static func == (lhs: MouseEvent.Event, rhs: MouseEvent.Event) -> Bool {
        lhs.toString == rhs.toString
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
        lhs.toString == rhs.toString
    }
}
