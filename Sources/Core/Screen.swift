////
///  Screen.swift
//

import Foundation
import Darwin.ncurses


enum Attr: Equatable {
    case underline
    case reverse
    case bold
    case color(Int)

    var rawValue: Int32 {
        switch self {
        case .underline: return 0x020000
        case .reverse:   return 0x040000
        case .bold:      return 0x200000
        case let .color(color):
            return COLOR_PAIR(min(Int32(max(color, -1)), COLORS))
        }
    }

    static func == (lhs: Attr, rhs: Attr) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

protocol TextType {
    var text: String? { get }
    var attrs: [Attr] { get }
}

struct Text: TextType {
    let text: String?
    let attrs: [Attr]

    init(_ text: String?, attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: TextType {
    var text: String? { return self }
    var attrs: [Attr] { return [] }
}

protocol ScreenType {
    var size: Size { get }
    func render(_: Component) -> Buffer
    func render(buffer _: Buffer)
    func setup()
    func teardown()
    func nextEvent() -> Event?
    func resized(height: Int, width: Int)
}

func ncurses_refresh() {
    refresh()
}


class Screen: ScreenType {
    var size: Size { return Size(width: Int(getmaxx(stdscr)), height: Int(getmaxy(stdscr))) }
    var prevBuffer: Buffer

    init() {
        prevBuffer = Buffer(size: .zero)
    }

    func render(_ component: Component) -> Buffer {
        let buffer = component.render(size: size)
        render(buffer: buffer)
        return buffer
    }

    func render(buffer: Buffer) {
        let chars = buffer.chars
        let prevChars = prevBuffer.chars
        prevBuffer = buffer

        for (y, prevRow) in prevChars {
            guard y >= 0 && y < size.height else { continue }
            let row = chars[y] ?? [:]
            for (x, _) in prevRow {
                guard x >= 0 && x < size.width else { continue }
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
        let e = getch()
        return Event(e)
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
        use_default_colors()

        for i: Int16 in Int16(0) ..< Int16(COLOR_PAIRS) {
            init_pair(i, -1, -1)
        }

        mousemask(0xFFFFFFF, nil)

        clear()
    }

    func teardown() {
        endwin()
    }
}
