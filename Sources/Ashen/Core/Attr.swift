////
///  Attr.swift
//

import Darwin.ncurses

enum Attr {
    case underline
    case reverse
    case bold
    case color(Int)

    static let systemBlack = Int(COLOR_BLACK)
    static let systemRed = Int(COLOR_RED)
    static let systemGreen = Int(COLOR_GREEN)
    static let systemYellow = Int(COLOR_YELLOW)
    static let systemBlue = Int(COLOR_BLUE)
    static let systemMagenta = Int(COLOR_MAGENTA)
    static let systemCyan = Int(COLOR_CYAN)
    static let systemWhite = Int(COLOR_WHITE)

    static let black = 16
    static let red = 17
    static let green = 18
    static let yellow = 19
    static let blue = 20
    static let magenta = 21
    static let cyan = 22
    static let white = 23
}
