////
///  TermboxScreen.swift
//


import Termbox


public class TermboxScreen: ScreenType {
    public var size: Size { return Size(width: Int(Termbox.width), height: Int(Termbox.height)) }
    private var extraEvents: [Event] = []

    public init() {
    }

    public func setup() throws {
        try Termbox.initialize()
        Termbox.inputModes = [.esc, .mouse]
        Termbox.present()
    }

    public func teardown() {
        Termbox.shutdown()
    }

    public func render(window: Component) -> Buffer {
        let buffer = window.render(size: size)
        render(buffer: buffer)
        return buffer
    }

    public func render(buffer: Buffer) {
        let chars = buffer.chars

        Termbox.clear()

        for (y, row) in chars {
            guard y >= 0 && y < size.height else { continue }
            for (x, char) in row {
                guard x >= 0 && x < size.width, let string = char.string else { continue }

                Termbox.puts(x: Int32(x), y: Int32(y), string: string, foreground: foregroundAttrs(char.attrs), background: backgroundAttrs(char.attrs))
            }
        }

        Termbox.present()
    }

    public func nextEvent() -> Event? {
        if extraEvents.count > 0 { return extraEvents.removeFirst() }

        let termboxEvent = Termbox.peekEvent(timeoutInMilliseconds: 1)

        if case .key(_, .esc) = termboxEvent {
            return nextEscEvent()
        }
        return convertTermboxEvent(termboxEvent)
    }

    private func convertTermboxEvent(_ termboxEvent: TermboxEvent) -> Event? {
        switch termboxEvent {
        case let .key(_, value):
            if let key = termBoxKey(value) {
                return .key(key)
            }
            else if let button = termBoxMouse(value) {
                return .click(button)
            }
        case let .character(_, value):
            guard let key = termBoxCharacter(value) else { return nil }
            return .key(key)
        case let .resize(width, height):
            return .window(width: Int(width), height: Int(height))
        case let .mouse(x, y):
            return .mouse(Int(x), Int(y))
        default:
            break
        }
        return nil
    }

    private func nextEscEvent() -> Event {
        var events: [TermboxEvent] = []
        var extraEvent: Event?
        var done = false
        while !done {
            let termboxEvent = Termbox.peekEvent(timeoutInMilliseconds: 1)

            switch termboxEvent {
            case .timeout:
                done = true
            case .key, .character:
                events.append(termboxEvent)
            default:
                extraEvent = convertTermboxEvent(termboxEvent)
                done = true
            }
        }

        let chains: [EscapeSequence] = [
            EscapeSequence(.key_shift_down) { return "[1;2B" },
            EscapeSequence(.key_shift_up) { return "[1;2A" },
            EscapeSequence(.key_shift_left) { return "[1;2D" },
            EscapeSequence(.key_shift_right) { return "[1;2C" },
            EscapeSequence(.key_alt_down) { return "[1;9B" },
            EscapeSequence(.key_alt_up) { return "[1;9A" },
            EscapeSequence(.key_alt_left) { return "[1;9D" },
            EscapeSequence(.key_alt_right) { return "[1;9C" },
            EscapeSequence(.key_alt_left) { return "b" },
            EscapeSequence(.key_alt_right) { return "f" },
            EscapeSequence(.key_shift_home) { return "[1;2H" },
            EscapeSequence(.key_shift_end) { return "[1;2F" },
            EscapeSequence(.signal_alt_bslash) { return "\\" },
            EscapeSequence(.key_backtab) { return "[Z" },
        ]
        let matchEvent: Event? = chains.reduce(nil) { event, chain in
            return event ?? chain.match(events)
        }
        if let matchEvent = matchEvent {
            if let extraEvent = extraEvent {
                extraEvents.append(extraEvent)
            }
            return matchEvent
        }
        else {
            extraEvents += events.compactMap(convertTermboxEvent)
            if let extraEvent = extraEvent {
                extraEvents.append(extraEvent)
            }
            return .key(.key_esc)
        }
    }

    private func foregroundAttrs(_ attrs: [Attr]) -> Attributes {
        return attrs.reduce(Attributes.default) { memo, attr -> Attributes in
            switch attr {
            case .background:
                return memo
            default:
                return memo.union(attr.toTermbox)
            }
        }
    }

    private func backgroundAttrs(_ attrs: [Attr]) -> Attributes {
        return attrs.reduce(Attributes.default) { memo, attr -> Attributes in
            switch attr {
            case .foreground:
                return memo
            default:
                return memo.union(attr.toTermbox)
            }
        }
    }

    private func termBoxMouse(_ mouse: Key) -> MouseButton? {
        switch mouse {
        case .mouseLeft:
            return .left
        case .mouseRight:
            return .right
        case .mouseMiddle:
            return .middle
        case .mouseRelease:
            return .release
        case .mouseWheelUp:
            return .wheelUp
        case .mouseWheelDown:
            return .wheelDown
        default:
            return nil
        }
    }

    private func termBoxKey(_ key: Key) -> KeyEvent? {
        switch key {
        case .ctrl2:
            return .signal_ctrl_at
        case .ctrlA:
            return .signal_ctrl_a
        case .ctrlB:
            return .signal_ctrl_b
        case .ctrlC:
            return .signal_ctrl_c
        case .ctrlD:
            return .signal_ctrl_d
        case .ctrlE:
            return .signal_ctrl_e
        case .ctrlF:
            return .signal_ctrl_f
        case .ctrlG:
            return .signal_ctrl_g
        case .backspace:
            return .key_backspace
        case .tab:
            return .key_tab
        case .ctrlJ:
            return .signal_ctrl_j
        case .ctrlK:
            return .signal_ctrl_k
        case .ctrlL:
            return .signal_ctrl_l
        case .enter:
            return .key_enter
        case .ctrlN:
            return .signal_ctrl_n
        case .ctrlO:
            return .signal_ctrl_o
        case .ctrlP:
            return .signal_ctrl_p
        case .ctrlQ:
            return .signal_ctrl_q
        case .ctrlR:
            return .signal_ctrl_r
        case .ctrlS:
            return .signal_ctrl_s
        case .ctrlT:
            return .signal_ctrl_t
        case .ctrlU:
            return .signal_ctrl_u
        case .ctrlV:
            return .signal_ctrl_v
        case .ctrlW:
            return .signal_ctrl_w
        case .ctrlX:
            return .signal_ctrl_x
        case .ctrlY:
            return .signal_ctrl_y
        case .ctrlZ:
            return .signal_ctrl_z
        case .esc:
            return .key_esc
        case .ctrlBackslash:
            return .signal_ctrl_bslash
        case .ctrlRightBracket:
            return .signal_ctrl_rbracket
        case .ctrl6:
            return .signal_ctrl_6
        case .ctrlSlash:
            return .signal_ctrl_fslash
        case .space:
            return .key_space
        case .f1:
            return .key_f1
        case .f2:
            return .key_f2
        case .f3:
            return .key_f3
        case .f4:
            return .key_f4
        case .f5:
            return .key_f5
        case .f6:
            return .key_f6
        case .f7:
            return .key_f7
        case .f8:
            return .key_f8
        case .f9:
            return .key_f9
        case .f10:
            return .key_f10
        case .f11:
            return .key_f11
        case .f12:
            return .key_f12
        case .insert:
            return .key_insert
        case .delete:
            return .key_delete
        case .home:
            return .key_home
        case .end:
            return .key_end
        case .pageUp:
            return .key_pageup
        case .pageDown:
            return .key_pagedown
        case .arrowUp:
            return .key_up
        case .arrowDown:
            return .key_down
        case .arrowLeft:
            return .key_left
        case .arrowRight:
            return .key_right
        default:
            return nil
        }
    }

    private func termBoxCharacter(_ character: UnicodeScalar) -> KeyEvent? {
        guard
            character.value < UInt16.max,
            let key = KeyEvent(rawValue: UInt16(character.value))
        else { return nil }
        return key
    }
}
