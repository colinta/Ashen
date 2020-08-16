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

    case gray
    case grayscale(AttrSize)
    case brightRed
    case brightGreen
    case brightYellow
    case brightBlue
    case brightMagenta
    case brightCyan
    case brightWhite

    case any(AttrSize)

    var toTermbox: TermboxAttributes {
        switch self {
        case .none:
            return .default
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

        case .gray:
            return TermboxAttributes(rawValue: 8)
        case .brightRed:
            return TermboxAttributes(rawValue: 9)
        case .brightGreen:
            return TermboxAttributes(rawValue: 10)
        case .brightYellow:
            return TermboxAttributes(rawValue: 11)
        case .brightBlue:
            return TermboxAttributes(rawValue: 12)
        case .brightMagenta:
            return TermboxAttributes(rawValue: 13)
        case .brightCyan:
            return TermboxAttributes(rawValue: 14)
        case .brightWhite:
            return TermboxAttributes(rawValue: 15)

        case .black:
            return .black

        case let .grayscale(shade):
            let clamped = min(23, max(0, shade))
            return TermboxAttributes(rawValue: 232 + clamped)

        case let .any(color):
            guard color >= 0 && color < 256 else { return .default }
            return TermboxAttributes(rawValue: color)
        }
    }

    public static func == (lhs: Color, rhs: Color) -> Bool {
        lhs.toTermbox == rhs.toTermbox
    }
}
