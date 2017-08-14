////
///  Attr.swift
//

import Darwin.ncurses

enum Attr {
    case underline
    case reverse
    case bold
    case color(Int)

    static let black = Int(COLOR_BLACK)
    static let red = Int(COLOR_RED)
    static let green = Int(COLOR_GREEN)
    static let yellow = Int(COLOR_YELLOW)
    static let blue = Int(COLOR_BLUE)
    static let magenta = Int(COLOR_MAGENTA)
    static let cyan = Int(COLOR_CYAN)
    static let white = Int(COLOR_WHITE)
}
