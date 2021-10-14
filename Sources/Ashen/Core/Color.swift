////
///  Color.swift
//

import Termbox

public enum Color: Equatable {
    case none
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan
    case white
    case gray
    case black

    case grayscale(AttrSize)

    case brightRed
    case brightGreen
    case brightYellow
    case brightBlue
    case brightMagenta
    case brightCyan
    case brightWhite

    // case darkestGray
    // case darkerGray
    // case darkGray
    // case lightGray
    // case lightestGray

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
            return .lighterGray

        case .gray:
            return .mediumGray
        case .brightRed:
            return .lightRed
        case .brightGreen:
            return .lightGreen
        case .brightYellow:
            return .lightYellow
        case .brightBlue:
            return .lightBlue
        case .brightMagenta:
            return .lightMagenta
        case .brightCyan:
            return .lightCyan
        case .brightWhite:
            return .white

        // case .darkestGray:
        //     return .darkestGray
        // case .darkerGray:
        //     return .darkerGray
        // case .darkGray:
        //     return .darkGray
        // case .lightGray:
        //     return .lightGray
        // case .lightestGray:
        //     return .lightestGray

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
