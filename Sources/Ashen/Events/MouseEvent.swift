////
///  MouseEvent.swift
//

public enum MouseEvent {
    public enum Button {
        case left
        case middle
        case right
    }
    public enum Direction {
        case up
        case down
    }

    case move(Int, Int)
    case click(Button)
    case scroll(Direction)
    case release

}

public extension MouseEvent {
    var toString: String {
        switch self {
        case .release:
            return "release"
        case let .move(x, y):
            return "move(\(x), \(y))"
        case let .click(btn):
            return "click(\(btn))"
        case let .scroll(direction):
            return "scroll(\(direction))"
        }
    }
}

extension MouseEvent: Equatable {
    public static func == (lhs: MouseEvent, rhs: MouseEvent) -> Bool {
        return lhs.toString == rhs.toString
    }
}
