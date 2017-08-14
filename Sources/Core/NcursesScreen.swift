////
///  NcursesScreen.swift
//


import Darwin.ncurses


func ncurses_refresh() {
    refresh()
}


class NcursesScreen: ScreenType {
    var size: Size { return Size(width: Int(getmaxx(stdscr)), height: Int(getmaxy(stdscr))) }
    var prevBuffer: Buffer
    var colorIndex: Int = 1

    init() {
        prevBuffer = Buffer(size: .zero)
    }

    private func attrValue(_ attrs: [Attr]) -> Int32 {
        return attrs.reduce(0 as Int32) { $0 | attrValue($1) }
    }
    private func attrValue(_ attr: Attr) -> Int32 {
        switch attr {
        case .underline: return 0x020000
        case .reverse:   return 0x040000
        case .bold:      return 0x200000
        case let .color(color):
            return COLOR_PAIR(min(Int32(max(color, -1)), COLORS))
        }
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
                let prevChar = prevRow[x] ?? AttrChar("")
                if prevChar.string != char.string || attrValue(prevChar.attrs) != attrValue(char.attrs) {
                    move(Int32(y), Int32(x))
                    for attr in char.attrs {
                        attron(attrValue(attr))
                    }
                    addstr(char.string ?? " ")
                    for attr in char.attrs {
                        attroff(attrValue(attr))
                    }
                }
            }
        }

        ncurses_refresh()
    }

    func nextEvent() -> Event? {
        if let event = windowEvent {
            windowEvent = nil
            return event
        }
        let e = getch()
        return Event(e)
    }

    func setup() {
        setlocale(LC_ALL, "")
        newterm(nil, stderr, stdin)
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

        let handleWinch: @convention(c) (Int32) -> Void = { signal in
            endwin()
            sync {
                windowEvent = .window(width: Int(getmaxx(stdscr)), height: Int(getmaxy(stdscr)))
            }
        }
        signal(SIGWINCH, handleWinch)
    }

    func initColor(_ index: Int, fg: (Int, Int, Int)?, bg: (Int, Int, Int)?) {
        let colorIndex1: Int16
        let colorIndex2: Int16

        if let fg = fg {
            colorIndex1 = Int16(colorIndex)
            colorIndex += 1
            init_color(colorIndex1, Int16(fg.0), Int16(fg.1), Int16(fg.2))
        }
        else {
            colorIndex1 = -1
        }

        if let bg = bg {
            colorIndex2 = Int16(colorIndex)
            colorIndex += 1
            init_color(colorIndex2, Int16(bg.0), Int16(bg.1), Int16(bg.2))
        }
        else {
            colorIndex2 = -1
        }

        init_pair(Int16(index), colorIndex1, colorIndex2)
    }

    func teardown() {
        endwin()
    }

    static func end() {
        endwin()
    }
}

private var windowEvent: Event?
