////
///  TermboxScreen.swift
//


import Termbox


public class TermboxScreen: ScreenType {
    public var size: Size { return Size(width: Int(Termbox.width), height: Int(Termbox.height)) }

    public init() {
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
                guard x >= 0 && x < size.width else { continue }

                // for attr in char.attrs {
                //     attron(attrValue(attr))
                // }
                Termbox.puts(x: Int32(x), y: Int32(y), string: char.string ?? "")
                // for attr in char.attrs {
                //     attroff(attrValue(attr))
                // }
            }
        }

        Termbox.present()
    }

    public func nextEvent() -> Event? {
        let e = Termbox.peekEvent(timeoutInMilliseconds: 15)  // 15ms ~= 1/60s
        switch e {
        case let .key(_, value):
            return .key(termBoxKey(value))
        case let .character(_, value):
            return .key(termBoxCharacter(value))
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

    public func setup() throws {
        try Termbox.initialize()
        Termbox.present()
    }

    public func teardown() {
        Termbox.shutdown()
    }

    private func termBoxKey(_ key: Key) -> KeyEvent {
        debug("=============== \(#file) line \(#line) ===============")
        debug("key: \(key)")
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
            return .unrecognized
        }
    }

    private func termBoxCharacter(_ character: UnicodeScalar) -> KeyEvent {
        let key = KeyEvent(rawValue: UInt16(character.value)) ?? .unrecognized
        debug("=============== \(#file) line \(#line) ===============")
        debug("character: \(character)")
        debug("key: \(key)")
        return key
    }
}
