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
