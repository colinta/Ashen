////
///  Color.swift
//

import Termbox

public enum Color: Equatable {
    case none
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
    case any(AttrSize)

    var toTermbox: TermboxAttributes {
        switch self {
        case .none:
            return .default
        case .black:
            return .black
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .blue:
            return .blue
        case .magenta:
            return .magenta
        case .cyan:
            return .cyan
        case .white:
            return .white

        case let .any(color):
            guard color >= 0 && color < 256 else { return .default }
            return TermboxAttributes(rawValue: color)
        }
    }

    public static func == (lhs: Color, rhs: Color) -> Bool {
        lhs.toTermbox == rhs.toTermbox
    }
}
