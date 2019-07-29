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
        Termbox.enableMouse()
        Termbox.outputMode = .trueColor
        Termbox.clear(foreground: .default, background: .default)
        Termbox.render()
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
            for (x, attrChar) in row {
                guard x >= 0 && x < size.width, let string = attrChar.char?.unicodeScalars.first else { continue }

                let foreground = foregroundAttrs(attrChar.attrs)
                let background = backgroundAttrs(attrChar.attrs)
                Termbox.putc(x: Int32(x), y: Int32(y), char: string, foreground: foreground, background: background)
            }
        }

        Termbox.render()
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
            else if let mouse = termBoxMouse(value) {
                return .mouse(mouse)
            }
        case let .character(_, value):
            guard let key = termBoxCharacter(value) else { return nil }
            return .key(key)
        case let .resize(width, height):
            return .window(width: Int(width), height: Int(height))
        case let .mouse(x, y):
            return .mouse(.move(Int(x), Int(y)))
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
            easyAltChar(),
            EscapeSequence(.ctrl(.alt(.tab))) { return "\t" },
            EscapeSequence(.backtab) { return "[Z" },
            EscapeSequence(.alt(.down)) { return "[1;9B" },
            EscapeSequence(.alt(.up)) { return "[1;9A" },
            EscapeSequence(.alt(.left)) { return "[1;9D" },
            EscapeSequence(.alt(.right)) { return "[1;9C" },
            // classic
            EscapeSequence(.shift(.down)) { return "[1;10B" },
            EscapeSequence(.shift(.up)) { return "[1;10A" },
            EscapeSequence(.shift(.left)) { return "[1;10D" },
            EscapeSequence(.shift(.right)) { return "[1;10C" },
            // modern
            EscapeSequence(.shift(.down)) { return "[1;2B" },
            EscapeSequence(.shift(.up)) { return "[1;2A" },
            EscapeSequence(.shift(.left)) { return "[1;2D" },
            EscapeSequence(.shift(.right)) { return "[1;2C" },
            // home/end
            EscapeSequence(.alt(.home)) { return "[1;9H" },
            EscapeSequence(.alt(.end)) { return "[1;9F" },
            EscapeSequence(.alt(.shift(.home))) { return "[1;10H" },
            EscapeSequence(.alt(.shift(.end))) { return "[1;10F" },
            EscapeSequence(.ctrl(.alt(.home))) { return "[1;13H" },
            EscapeSequence(.ctrl(.alt(.end))) { return "[1;13F" },
            EscapeSequence(.shift(.home)) { return "[1;2H" },
            EscapeSequence(.shift(.end)) { return "[1;2F" },
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
            return .key(.esc)
        }
    }

    private func foregroundAttrs(_ attrs: [Attr]) -> Attributes {
        let retval = attrs.reduce(Attributes.zero) { memo, attr -> Attributes in
            switch attr {
            case .background:
                return memo
            default:
                return memo.union(attr.toTermbox)
            }
        }
        if retval.rawValue == 0 {
            return .default
        }
        return retval
    }

    private func backgroundAttrs(_ attrs: [Attr]) -> Attributes {
        let retval = attrs.reduce(Attributes.zero) { memo, attr -> Attributes in
            switch attr {
            case .foreground:
                return memo
            default:
                return memo.union(attr.toTermbox)
            }
        }
        if retval.rawValue == 0 {
            return .default
        }
        return retval
    }
}

private func easyAltChar() -> EscapeSequence{
    return EscapeSequence(
        { events in
            guard events.count == 1 else { fatalError("already guarded against") }

            let event = events[0]
            if case let .character(_, eventValue) = event,
                case let .char(key) = termBoxCharacter(eventValue)!
            {
                return .alt(.char(key))
            }
            if case let .key(_, eventValue) = event,
                case let .fn(key) = termBoxKey(eventValue)!
            {
                return .alt(.fn(key))
            }
            if case let .key(_, eventValue) = event,
                case let .ctrl(key) = termBoxKey(eventValue)!
            {
                return .ctrl(.alt(key.toAltKey))
            }
            else {
                fatalError("already guarded against")
            }
        },
        { events in
            guard events.count == 1 else { return false }

            let event = events[0]
            if case let .character(_, eventValue) = event,
                termBoxCharacter(eventValue) != nil
            {
                return true
            }
            if case let .key(_, eventValue) = event,
                let key = termBoxKey(eventValue),
                case .fn = key
            {
                return true
            }
            if case let .key(_, eventValue) = event,
                let key = termBoxKey(eventValue),
                case .ctrl = key
            {
                return true
            }
            else {
                return false
            }
        })
}

private func termBoxMouse(_ mouse: Key) -> MouseEvent? {
    switch mouse {
    case .mouseLeft:
        return .click(.left)
    case .mouseRight:
        return .click(.right)
    case .mouseMiddle:
        return .click(.middle)
    case .mouseRelease:
        return .release
    case .mouseWheelUp:
        return .scroll(.up)
    case .mouseWheelDown:
        return .scroll(.down)
    default:
        return nil
    }
}

private func termBoxKey(_ key: Key) -> KeyEvent? {
    switch key {
    case .ctrl2:
        return .ctrl(.two)
    case .ctrlA:
        return .ctrl(.a)
    case .ctrlB:
        return .ctrl(.b)
    case .ctrlC:
        return .ctrl(.c)
    case .ctrlD:
        return .ctrl(.d)
    case .ctrlE:
        return .ctrl(.e)
    case .ctrlF:
        return .ctrl(.f)
    case .ctrlG:
        return .ctrl(.g)
    case .ctrlJ:
        return .ctrl(.j)
    case .ctrlK:
        return .ctrl(.k)
    case .ctrlL:
        return .ctrl(.l)
    case .enter:
        return .enter
    case .ctrlN:
        return .ctrl(.n)
    case .ctrlO:
        return .ctrl(.o)
    case .ctrlP:
        return .ctrl(.p)
    case .ctrlQ:
        return .ctrl(.q)
    case .ctrlR:
        return .ctrl(.r)
    case .ctrlS:
        return .ctrl(.s)
    case .ctrlT:
        return .ctrl(.t)
    case .ctrlU:
        return .ctrl(.u)
    case .ctrlV:
        return .ctrl(.v)
    case .ctrlW:
        return .ctrl(.w)
    case .ctrlX:
        return .ctrl(.x)
    case .ctrlY:
        return .ctrl(.y)
    case .ctrlZ:
        return .ctrl(.z)
    case .ctrlBackslash:
        return .ctrl(.backslash)
    case .ctrlRightBracket:
        return .ctrl(.rightBracket)
    case .ctrl6:
        return .ctrl(.six)
    case .ctrlSlash:
        return .ctrl(.underscore)
    case .backspace:
        return .backspace
    case .tab:
        return .tab
    case .esc:
        return .esc
    case .space:
        return .space
    case .f1:
        return .f1
    case .f2:
        return .f2
    case .f3:
        return .f3
    case .f4:
        return .f4
    case .f5:
        return .f5
    case .f6:
        return .f6
    case .f7:
        return .f7
    case .f8:
        return .f8
    case .f9:
        return .f9
    case .f10:
        return .f10
    case .f11:
        return .f11
    case .f12:
        return .f12
    case .insert:
        return .insert
    case .delete:
        return .delete
    case .home:
        return .home
    case .end:
        return .end
    case .pageUp:
        return .pageUp
    case .pageDown:
        return .pageDown
    case .arrowUp:
        return .up
    case .arrowDown:
        return .down
    case .arrowLeft:
        return .left
    case .arrowRight:
        return .right
    default:
        return nil
    }
}

private func termBoxCharacter(_ character: UnicodeScalar) -> KeyEvent? {
    guard
        character.value < UInt16.max,
        let key = KeyEvent(character: UInt16(character.value))
    else { return nil }
    return key
}
