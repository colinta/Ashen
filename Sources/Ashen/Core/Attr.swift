////
///  Attr.swift
//

import Darwin.ncurses

public enum Attr {
    case underline
    case reverse
    case bold
    case color(Int)

    public static let systemBlack = Int(COLOR_BLACK)
    public static let systemRed = Int(COLOR_RED)
    public static let systemGreen = Int(COLOR_GREEN)
    public static let systemYellow = Int(COLOR_YELLOW)
    public static let systemBlue = Int(COLOR_BLUE)
    public static let systemMagenta = Int(COLOR_MAGENTA)
    public static let systemCyan = Int(COLOR_CYAN)
    public static let systemWhite = Int(COLOR_WHITE)

    public static let black = 16
    public static let red = 17
    public static let green = 18
    public static let yellow = 19
    public static let blue = 20
    public static let magenta = 21
    public static let cyan = 22
    public static let white = 23
}
