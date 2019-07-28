////
///  Color.swift
//

import Termbox

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
    case brightBlack
    case brightRed
    case brightGreen
    case brightYellow
    case brightBlue
    case brightMagenta
    case brightCyan
    case brightWhite
    case any(UInt16)

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

        case .brightBlack:
            return Attributes(rawValue: 0x09)
        case .brightRed:
            return Attributes(rawValue: 0x0a)
        case .brightGreen:
            return Attributes(rawValue: 0x0b)
        case .brightYellow:
            return Attributes(rawValue: 0x0c)
        case .brightBlue:
            return Attributes(rawValue: 0x0d)
        case .brightMagenta:
            return Attributes(rawValue: 0x0e)
        case .brightCyan:
            return Attributes(rawValue: 0x0f)
        case .brightWhite:
            return Attributes(rawValue: 0x10)

        case let .any(color):
            guard color >= 0 && color < 0x0100 else { return .default }
            return Attributes(rawValue: color)
        }
    }
}
