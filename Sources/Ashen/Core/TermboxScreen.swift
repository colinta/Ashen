////
///  TermboxScreen.swift
//


import Termbox


class TermboxScreen: ScreenType {
    var size: Size { return Size(width: Int(Termbox.width), height: Int(Termbox.height)) }
    var colorIndex: Int = 1

    private var windowEvent: Event?

    init() {
    }

    private func attrValue(_ attrs: [Attr]) -> Int32 {
        // return attrs.reduce(0 as Int32) { $0 | attrValue($1) }
        return 0
    }
    private func attrValue(_ attr: Attr) -> Int32 {
        // switch attr {
        // case .underline: return 0x020000
        // case .reverse:   return 0x040000
        // case .bold:      return 0x200000
        // case let .color(color):
        //     return COLOR_PAIR(min(Int32(max(color, -1)), COLORS))
        // }
        return 0
    }

    func render(_ component: Component) -> Buffer {
        let buffer = component.render(size: size)
        render(buffer: buffer)
        return buffer
    }

    func render(buffer: Buffer) {
        let chars = buffer.chars

        Termbox.clear()

        for (y, row) in chars {
            guard y >= 0 && y < size.height else { continue }
            for (x, char) in row {
                guard x >= 0 && x < size.width else { continue }

                // for attr in char.attrs {
                //     attron(attrValue(attr))
                // }
                // Termbox.put(x: Int32(x), y: Int32(y), character: (char.string ?? " ") as UnicodeScalar)
                // for attr in char.attrs {
                //     attroff(attrValue(attr))
                // }
            }
        }

        Termbox.present()
    }

    func nextEvent() -> Event? {
        if let event = windowEvent {
            windowEvent = nil
            return event
        }

        let e = Termbox.peekEvent(timeoutInMilliseconds: 15)  // 15ms ~= 1/60s
        switch e {
        case let .key(modifier, value):
            return .key(.signal_ctrl_c)
        case let .character(modifier, value):
            return .key(.signal_ctrl_c)
        case let .resize(width, height):
            return .window(width: Int(width), height: Int(height))
        case let .mouse(x, y):
            return .mouse(Int(x), Int(y))
        case .timeout:
            return nil
        case .other:
            return nil
        }
    }

    func setup() throws {
        try Termbox.initialize()
        Termbox.present()
    }

    func teardown() {
        Termbox.shutdown()
    }
}
