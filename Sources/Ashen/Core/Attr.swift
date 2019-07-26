////
///  Attr.swift
//

import Termbox

public enum Attr {
    case underline
    case reverse
    case bold
    case foreground(Color)
    case background(Color)

    var toTermbox: Attributes {
        switch self {
        case .underline: return .underline
        case .reverse: return .reverse
        case .bold: return .bold
        case let .foreground(color): return color.toTermbox
        case let .background(color): return color.toTermbox
        }
    }
}

public enum Color {
    case none
    case black
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white

    var toTermbox: Attributes {
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
        }
    }
}
