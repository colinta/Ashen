////
///  Attr.swift
//

import Termbox

public enum Attr: Equatable {
    case underline
    case reverse
    case bold
    case foreground(Color)
    case background(Color)

    var toTermbox: TermboxAttributes {
        switch self {
        case .underline: return .underline
        case .reverse: return .reverse
        case .bold: return .bold
        case let .foreground(color): return color.toTermbox
        case let .background(color): return color.toTermbox
        }
    }

    public static func == (lhs: Attr, rhs: Attr) -> Bool {
        switch (lhs, rhs) {
        case (.underline, .underline):
            return true
        case (.reverse, .reverse):
            return true
        case (.bold, .bold):
            return true
        default:
            break
        }

        if case let .foreground(lhsColor) = lhs, case let .foreground(rhsColor) = rhs {
            return lhsColor == rhsColor
        }

        if case let .background(lhsColor) = lhs, case let .background(rhsColor) = rhs {
            return lhsColor == rhsColor
        }

        return false
    }
}
