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

    private func bufferOutput(_ buffer: Buffer) -> [String] {
        var output: [String] = []
        typealias LineTuple = (x: Int, char: TextType)
        let lines: [[LineTuple]] = buffer.chars
            .map { (y: Int, line: [Int: TextType]) -> (y: Int, line: [LineTuple]) in
                let lineTuple = line.map { (x: Int, char: TextType) -> LineTuple in
                        return (x: x, char: char)
                    }
                    .sorted { a, b in return a.x < b.x }
                return (y: y, line: lineTuple)
            }
            .sorted { (a, b) in return a.y < b.y }
            .map { (y, line) in return line }
        for line in lines {
            var lineOutput = ""
            if lineOutput != "" {
                lineOutput += "\n"
            }

            var prevX = (line.min(by: { a, b in return a.x < b.x })?.x) ?? 0
            var prevAttr = ""
            for (x, char) in line {
                while prevX < x {
                    if prevAttr != "" {
                        lineOutput += "\u{1b}[0m"
                        prevAttr = ""
                    }
                    lineOutput += " "
                    prevX += 1
                }

                let text = char.text ?? " "
                let attr = attrValue(char.attrs)
                if prevAttr != attr {
                    if prevAttr != "" {
                        lineOutput += "\u{1b}[0m"
                    }
                    lineOutput += attr
                    prevAttr = attr
                }
                lineOutput += text
                prevX += 1
            }

            if prevAttr != "" {
                lineOutput += "\u{1b}[0m"
            }
            output.append(lineOutput)
        }

        return output
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
