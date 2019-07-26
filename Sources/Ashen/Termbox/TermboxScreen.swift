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
            EscapeSequence(.keyShiftDown) { return "[1;2B" },
            EscapeSequence(.keyShiftUp) { return "[1;2A" },
            EscapeSequence(.keyShiftLeft) { return "[1;2D" },
            EscapeSequence(.keyShiftRight) { return "[1;2C" },
            EscapeSequence(.keyAltDown) { return "[1;9B" },
            EscapeSequence(.keyAltUp) { return "[1;9A" },
            EscapeSequence(.keyAltLeft) { return "[1;9D" },
            EscapeSequence(.keyAltRight) { return "[1;9C" },
            EscapeSequence(.keyAltLeft) { return "b" },
            EscapeSequence(.keyAltRight) { return "f" },
            EscapeSequence(.keyShiftHome) { return "[1;2H" },
            EscapeSequence(.keyShiftEnd) { return "[1;2F" },
            EscapeSequence(.signalAltBslash) { return "\\" },
            EscapeSequence(.keyBacktab) { return "[Z" },
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
            return .key(.keyEsc)
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
            return .signalCtrlAt
        case .ctrlA:
            return .signalCtrlA
        case .ctrlB:
            return .signalCtrlB
        case .ctrlC:
            return .signalCtrlC
        case .ctrlD:
            return .signalCtrlD
        case .ctrlE:
            return .signalCtrlE
        case .ctrlF:
            return .signalCtrlF
        case .ctrlG:
            return .signalCtrlG
        case .backspace:
            return .keyBackspace
        case .tab:
            return .keyTab
        case .ctrlJ:
            return .signalCtrlJ
        case .ctrlK:
            return .signalCtrlK
        case .ctrlL:
            return .signalCtrlL
        case .enter:
            return .keyEnter
        case .ctrlN:
            return .signalCtrlN
        case .ctrlO:
            return .signalCtrlO
        case .ctrlP:
            return .signalCtrlP
        case .ctrlQ:
            return .signalCtrlQ
        case .ctrlR:
            return .signalCtrlR
        case .ctrlS:
            return .signalCtrlS
        case .ctrlT:
            return .signalCtrlT
        case .ctrlU:
            return .signalCtrlU
        case .ctrlV:
            return .signalCtrlV
        case .ctrlW:
            return .signalCtrlW
        case .ctrlX:
            return .signalCtrlX
        case .ctrlY:
            return .signalCtrlY
        case .ctrlZ:
            return .signalCtrlZ
        case .esc:
            return .keyEsc
        case .ctrlBackslash:
            return .signalCtrlBslash
        case .ctrlRightBracket:
            return .signalCtrlRbracket
        case .ctrl6:
            return .signalCtrl6
        case .ctrlSlash:
            return .signalCtrlFslash
        case .space:
            return .keySpace
        case .f1:
            return .keyF1
        case .f2:
            return .keyF2
        case .f3:
            return .keyF3
        case .f4:
            return .keyF4
        case .f5:
            return .keyF5
        case .f6:
            return .keyF6
        case .f7:
            return .keyF7
        case .f8:
            return .keyF8
        case .f9:
            return .keyF9
        case .f10:
            return .keyF10
        case .f11:
            return .keyF11
        case .f12:
            return .keyF12
        case .insert:
            return .keyInsert
        case .delete:
            return .keyDelete
        case .home:
            return .keyHome
        case .end:
            return .keyEnd
        case .pageUp:
            return .keyPageup
        case .pageDown:
            return .keyPagedown
        case .arrowUp:
            return .keyUp
        case .arrowDown:
            return .keyDown
        case .arrowLeft:
            return .keyLeft
        case .arrowRight:
            return .keyRight
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
