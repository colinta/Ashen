////
///  Screen.swift
//

import Foundation
import Darwin.ncurses


enum Attr: Equatable {
    case normal
    case underline
    case reverse
    case bold
    case color(Int32)

    var rawValue: Int32 {
        switch self {
        case .normal:    return 0x000000
        case .underline: return 0x020000
        case .reverse:   return 0x040000
        case .bold:      return 0x200000
        case let .color(color): return COLOR_PAIR(color)
        }
    }

    static func == (lhs: Attr, rhs: Attr) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

protocol TextType {
    var text: String { get }
    var attrs: [Attr] { get }
}

struct Text: TextType {
    let text: String
    let attrs: [Attr]

    init(_ text: String, attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: TextType {
    var text: String { return self }
    var attrs: [Attr] { return [] }
}

protocol ScreenType {
    var size: Size { get }
    func render(_: ComponentType) -> Screen.Chars
    func render(chars _: Screen.Chars)
    func setup()
    func teardown()
    func nextEvent() -> Event?
    func resized(height: Int, width: Int)
}

func ncurses_refresh() {
    refresh()
}


class Screen: ScreenType {
    typealias Chars = [Int: [Int: TextType]]
    var size: Size { return Size(width: Int(getmaxx(stdscr)), height: Int(getmaxy(stdscr))) }
    var chars: Chars = [:]

    func render(_ component: ComponentType) -> Chars {
        render(chars: component.chars(in: size))
        return chars
    }

    func render(chars nextChars: Chars) {
        let prevChars = chars
        chars = nextChars

        for (y, prevRow) in prevChars {
            let row = chars[y] ?? [:]
            for (x, _) in prevRow {
                if row[x] == nil {
                    move(Int32(y), Int32(x))
                    addstr(" ")
                }
            }
        }

        for (y, row) in chars {
            guard y >= 0 && y < size.height else { continue }
            for (x, char) in row {
                guard x >= 0 && x < size.width else { continue }

                let prevRow = prevChars[y] ?? [:]
                let prevChar = prevRow[x] ?? ""
                if prevChar.text != char.text || prevChar.attrs != char.attrs {
                    move(Int32(y), Int32(x))
                    for attr in char.attrs {
                        attron(attr.rawValue)
                    }
                    addstr(char.text)
                    for attr in char.attrs {
                        attroff(attr.rawValue)
                    }
                }
            }
        }
        ncurses_refresh()
    }

    func nextEvent() -> Event? {
        return Event(getch())
    }

    func resized(height: Int, width: Int) {
    }

    func setup() {
        setlocale(LC_ALL, "")
        initscr()
        start_color()               // Support init_pair,
        raw()                       // Handle C-c, C-z, C-d, etc
        noecho()                    // Don't echo user input
        nonl()                      // Disable newline mode
        intrflush(stdscr, true)     // Prevent flush
        keypad(stdscr, true)        // Enable function and arrow keys
        curs_set(0)                 // Set cursor to invisible
        nodelay(stdscr, true)       // Don't block getch()

        init_pair(1, Int16(COLOR_BLACK), Int16(COLOR_GREEN))
        clear()

        mousemask(0xFFFFFFF, nil)
    }

    func teardown() {
        endwin()
    }
}
