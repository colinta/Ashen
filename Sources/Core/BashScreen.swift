////
///  BashScreen.swift
//

import Darwin


class BashScreen: ScreenType {
    var size: Size {
        var w = winsize()
        _ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
        return Size(width: Int(w.ws_col), height: Int(w.ws_row))
    }
    var prevBuffer: Buffer
    var colorIndex: Int = 1

    init() {
        prevBuffer = Buffer(size: .zero)
    }

    private func attrValue(_ attrs: [Attr]) -> String {
        guard attrs.count > 0 else { return "" }
        return "\u{1b}[" + attrs.map { attrValue($0) }.joined(separator: ";") + "m"
    }
    private func attrValue(_ attr: Attr) -> String {
        switch attr {
        case .bold:      return "1"
        case .underline: return "4"
        case .reverse:   return "7"
        case let .color(color):
            let ansiColor: Int
            if color < 8 {
                ansiColor = color + 30
            }
            else {
                ansiColor = (color - 7) + 40
            }
            return "\(ansiColor)"
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
                    print("\u{1b}[\(y + 1);\(x + 1)H ", terminator: "")
                }
            }
        }

        for (y, row) in chars {
            guard y >= 0 && y < size.height else { continue }
            for (x, char) in row {
                guard x >= 0 && x < size.width else { continue }

                let prevRow = prevChars[y] ?? [:]
                let prevChar = prevRow[x] ?? ""
                if prevChar.text != char.text || attrValue(prevChar.attrs) != attrValue(char.attrs) {
                    let c = char.text ?? " "
                    print("\u{1b}[\(y + 1);\(x + 1)H\(attrValue(prevChar.attrs))\(c)\u{1b}[0m", terminator: "")
                }
            }
        }
    }

    func nextEvent() -> Event? {
        let e = getch()
        if e > 0 {
            print("event: \(e)")
        }
        return Event(e)
    }

    func resized(height: Int, width: Int) {
    }

    func setup() {
        raw()                       // Handle C-c, C-z, C-d, etc
        keypad(stdscr, true)        // Enable function and arrow keys
        nodelay(stdscr, true)       // Don't block getch()

        // mousemask(0xFFFFFFF, nil)
        print("\u{1b}[s", terminator: "")
    }

    func initColor(_ index: Int, fg: (Int, Int, Int)?, bg: (Int, Int, Int)?) {
    }

    func teardown() {
        print("\u{1b}[u", terminator: "")
    }
}
