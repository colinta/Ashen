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
