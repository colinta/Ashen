public enum KeyEvent {
    case ctrl(CtrlKeyEvent)
    case alt(AltKeyEvent)
    case shift(ShiftKeyEvent)
    case char(CharKeyEvent)
    case fn(FnKeyEvent)

    // any signals that have common unix meaning are
    // named after that signal
    // (eg C-c int, C-t info, C-z suspend, C-\ quit)
    //
    // the rest are named after ASCII codes from http://www.ascii-code.com
    public static let signalNul: KeyEvent = .ctrl(.two)
    public static let signalSoh: KeyEvent = .ctrl(.a)
    public static let signalStx: KeyEvent = .ctrl(.b)
    public static let signalInt: KeyEvent = .ctrl(.c)
    public static let signalEot: KeyEvent = .ctrl(.d)
    public static let signalEnq: KeyEvent = .ctrl(.e)
    public static let signalAck: KeyEvent = .ctrl(.f)
    public static let signalBel: KeyEvent = .ctrl(.g)
    // public static let signalBs: KeyEvent = .ctrl(.backspace)
    public static let signalLf: KeyEvent = .ctrl(.j)
    public static let signalVt: KeyEvent = .ctrl(.k)
    public static let signalFf: KeyEvent = .ctrl(.l)
    public static let signalSo: KeyEvent = .ctrl(.n)
    public static let signalDiscard: KeyEvent = .ctrl(.o)
    public static let signalDle: KeyEvent = .ctrl(.p)
    public static let signalStart: KeyEvent = .ctrl(.q)
    public static let signalReprint: KeyEvent = .ctrl(.r)
    public static let signalStop: KeyEvent = .ctrl(.s)
    public static let signalInfo: KeyEvent = .ctrl(.t)
    public static let signalKill: KeyEvent = .ctrl(.u)
    public static let signalNext: KeyEvent = .ctrl(.v)
    public static let signalEtb: KeyEvent = .ctrl(.w)
    public static let signalCancel: KeyEvent = .ctrl(.x)
    public static let signalDsusp: KeyEvent = .ctrl(.y)
    public static let signalSuspend: KeyEvent = .ctrl(.z)
    public static let signalQuit: KeyEvent = .ctrl(.backslash)
    public static let signalGs: KeyEvent = .ctrl(.rightBracket)
    public static let signalRs: KeyEvent = .ctrl(.caret)
    public static let signalUs: KeyEvent = .ctrl(.underscore)
    public static let signalH: KeyEvent = .ctrl(.h)

    // shorthand for meta/function keys
    public static let tab: KeyEvent = .fn(.tab)
    public static let enter: KeyEvent = .fn(.enter)
    public static let esc: KeyEvent = .fn(.esc)
    public static let backspace: KeyEvent = .fn(.backspace)
    public static let backtab: KeyEvent = .fn(.backtab)
    public static let down: KeyEvent = .fn(.down)
    public static let up: KeyEvent = .fn(.up)
    public static let left: KeyEvent = .fn(.left)
    public static let right: KeyEvent = .fn(.right)
    public static let home: KeyEvent = .fn(.home)
    public static let f1: KeyEvent = .fn(.f1)
    public static let f2: KeyEvent = .fn(.f2)
    public static let f3: KeyEvent = .fn(.f3)
    public static let f4: KeyEvent = .fn(.f4)
    public static let f5: KeyEvent = .fn(.f5)
    public static let f6: KeyEvent = .fn(.f6)
    public static let f7: KeyEvent = .fn(.f7)
    public static let f8: KeyEvent = .fn(.f8)
    public static let f9: KeyEvent = .fn(.f9)
    public static let f10: KeyEvent = .fn(.f10)
    public static let f11: KeyEvent = .fn(.f11)
    public static let f12: KeyEvent = .fn(.f12)
    public static let pageDown: KeyEvent = .fn(.pageDown)
    public static let pageUp: KeyEvent = .fn(.pageUp)
    public static let end: KeyEvent = .fn(.end)
    public static let delete: KeyEvent = .fn(.delete)
    public static let insert: KeyEvent = .fn(.insert)

    // shorthand for printables
    public static let space: KeyEvent = .char(.space)
    public static let bang: KeyEvent = .char(.bang)
    public static let doubleQuote: KeyEvent = .char(.doubleQuote)
    public static let hash: KeyEvent = .char(.hash)
    public static let dollar: KeyEvent = .char(.dollar)
    public static let percent: KeyEvent = .char(.percent)
    public static let amp: KeyEvent = .char(.amp)
    public static let singleQuote: KeyEvent = .char(.singleQuote)
    public static let leftParen: KeyEvent = .char(.leftParen)
    public static let rightParen: KeyEvent = .char(.rightParen)
    public static let star: KeyEvent = .char(.star)
    public static let plus: KeyEvent = .char(.plus)
    public static let comma: KeyEvent = .char(.comma)
    public static let dash: KeyEvent = .char(.dash)
    public static let dot: KeyEvent = .char(.dot)
    public static let number0: KeyEvent = .char(.number0)
    public static let number1: KeyEvent = .char(.number1)
    public static let number2: KeyEvent = .char(.number2)
    public static let number3: KeyEvent = .char(.number3)
    public static let number4: KeyEvent = .char(.number4)
    public static let number5: KeyEvent = .char(.number5)
    public static let number6: KeyEvent = .char(.number6)
    public static let number7: KeyEvent = .char(.number7)
    public static let number8: KeyEvent = .char(.number8)
    public static let number9: KeyEvent = .char(.number9)
    public static let colon: KeyEvent = .char(.colon)
    public static let semicolon: KeyEvent = .char(.semicolon)
    public static let lt: KeyEvent = .char(.lt)
    public static let eq: KeyEvent = .char(.eq)
    public static let gt: KeyEvent = .char(.gt)
    public static let question: KeyEvent = .char(.question)
    public static let at: KeyEvent = .char(.at)
    public static let A: KeyEvent = .char(.A)
    public static let B: KeyEvent = .char(.B)
    public static let C: KeyEvent = .char(.C)
    public static let D: KeyEvent = .char(.D)
    public static let E: KeyEvent = .char(.E)
    public static let F: KeyEvent = .char(.F)
    public static let G: KeyEvent = .char(.G)
    public static let H: KeyEvent = .char(.H)
    public static let I: KeyEvent = .char(.I)
    public static let J: KeyEvent = .char(.J)
    public static let K: KeyEvent = .char(.K)
    public static let L: KeyEvent = .char(.L)
    public static let M: KeyEvent = .char(.M)
    public static let N: KeyEvent = .char(.N)
    public static let O: KeyEvent = .char(.O)
    public static let P: KeyEvent = .char(.P)
    public static let Q: KeyEvent = .char(.Q)
    public static let R: KeyEvent = .char(.R)
    public static let S: KeyEvent = .char(.S)
    public static let T: KeyEvent = .char(.T)
    public static let U: KeyEvent = .char(.U)
    public static let V: KeyEvent = .char(.V)
    public static let W: KeyEvent = .char(.W)
    public static let X: KeyEvent = .char(.X)
    public static let Y: KeyEvent = .char(.Y)
    public static let Z: KeyEvent = .char(.Z)
    public static let leftBracket: KeyEvent = .char(.leftBracket)
    public static let backslash: KeyEvent = .char(.backslash)
    public static let rightBracket: KeyEvent = .char(.rightBracket)
    public static let caret: KeyEvent = .char(.caret)
    public static let underscore: KeyEvent = .char(.underscore)
    public static let backtick: KeyEvent = .char(.backtick)
    public static let a: KeyEvent = .char(.a)
    public static let b: KeyEvent = .char(.b)
    public static let c: KeyEvent = .char(.c)
    public static let d: KeyEvent = .char(.d)
    public static let e: KeyEvent = .char(.e)
    public static let f: KeyEvent = .char(.f)
    public static let g: KeyEvent = .char(.g)
    public static let h: KeyEvent = .char(.h)
    public static let i: KeyEvent = .char(.i)
    public static let j: KeyEvent = .char(.j)
    public static let k: KeyEvent = .char(.k)
    public static let l: KeyEvent = .char(.l)
    public static let m: KeyEvent = .char(.m)
    public static let n: KeyEvent = .char(.n)
    public static let o: KeyEvent = .char(.o)
    public static let p: KeyEvent = .char(.p)
    public static let q: KeyEvent = .char(.q)
    public static let r: KeyEvent = .char(.r)
    public static let s: KeyEvent = .char(.s)
    public static let t: KeyEvent = .char(.t)
    public static let u: KeyEvent = .char(.u)
    public static let v: KeyEvent = .char(.v)
    public static let w: KeyEvent = .char(.w)
    public static let x: KeyEvent = .char(.x)
    public static let y: KeyEvent = .char(.y)
    public static let z: KeyEvent = .char(.z)
    public static let leftCurly: KeyEvent = .char(.leftCurly)
    public static let pipe: KeyEvent = .char(.pipe)
    public static let rightCurly: KeyEvent = .char(.rightCurly)
    public static let tilde: KeyEvent = .char(.tilde)
}

extension KeyEvent: Equatable {
    public static func == (lhs: KeyEvent, rhs: KeyEvent) -> Bool {
        lhs.toString == rhs.toString
    }
}

extension KeyEvent {
    public var isPrintable: Bool {
        switch self {
        case let .alt(key):
            return key.isPrintable
        case .char:
            return true
        default:
            return false
        }
    }

    public var toPrintable: String {
        switch self {
        case let .alt(key): return "\(key.toPrintable)"
        case let .char(key): return "\(key.toPrintable)"
        case let .fn(key): return "\(key.toPrintable)"
        default:
            return toString
        }
    }

    public var toString: String {
        switch self {
        case let .ctrl(key): return "⌃\(key.toString.uppercased())"
        case let .alt(key): return "⌥\(key.toString)"
        case let .shift(key): return "⇧\(key.toString)"
        case let .char(key): return "\(key.toString)"
        case let .fn(key): return "\(key.toString)"
        }
    }
}

public enum CtrlKeyEvent {
    case alt(AltKeyEvent)
    case two
    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case j
    case k
    case l
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z
    case backslash
    case rightBracket
    case caret
    case underscore
    case six
    case home
    case end
}

extension CtrlKeyEvent {
    public var toString: String {
        switch self {
        case let .alt(key): return "⌥\(key.toString)"
        case .two: return "2"
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .backslash: return "\\"
        case .rightBracket: return "]"
        case .caret: return "^"
        case .underscore: return "_"
        case .h: return "H"
        case .six: return "6"
        case .home: return "⤒"
        case .end: return "⤓"
        }
    }
}

extension CtrlKeyEvent: Equatable {
    public static func == (lhs: CtrlKeyEvent, rhs: CtrlKeyEvent) -> Bool {
        lhs.toString == rhs.toString
    }
}

public enum AltKeyEvent {
    case shift(ShiftKeyEvent)
    case char(CharKeyEvent)
    case fn(FnKeyEvent)

    // shorthand for meta/function keys
    public static let tab: AltKeyEvent = .fn(.tab)
    public static let enter: AltKeyEvent = .fn(.enter)
    public static let esc: AltKeyEvent = .fn(.esc)
    public static let backspace: AltKeyEvent = .fn(.backspace)
    public static let backtab: AltKeyEvent = .fn(.backtab)
    public static let down: AltKeyEvent = .fn(.down)
    public static let up: AltKeyEvent = .fn(.up)
    public static let left: AltKeyEvent = .fn(.left)
    public static let right: AltKeyEvent = .fn(.right)
    public static let home: AltKeyEvent = .fn(.home)
    public static let f1: AltKeyEvent = .fn(.f1)
    public static let f2: AltKeyEvent = .fn(.f2)
    public static let f3: AltKeyEvent = .fn(.f3)
    public static let f4: AltKeyEvent = .fn(.f4)
    public static let f5: AltKeyEvent = .fn(.f5)
    public static let f6: AltKeyEvent = .fn(.f6)
    public static let f7: AltKeyEvent = .fn(.f7)
    public static let f8: AltKeyEvent = .fn(.f8)
    public static let f9: AltKeyEvent = .fn(.f9)
    public static let f10: AltKeyEvent = .fn(.f10)
    public static let f11: AltKeyEvent = .fn(.f11)
    public static let f12: AltKeyEvent = .fn(.f12)
    public static let pageDown: AltKeyEvent = .fn(.pageDown)
    public static let pageUp: AltKeyEvent = .fn(.pageUp)
    public static let end: AltKeyEvent = .fn(.end)
    public static let delete: AltKeyEvent = .fn(.delete)
    public static let insert: AltKeyEvent = .fn(.insert)

    // shorthand for printables
    public static let space: AltKeyEvent = .char(.space)
    public static let bang: AltKeyEvent = .char(.bang)
    public static let doubleQuote: AltKeyEvent = .char(.doubleQuote)
    public static let hash: AltKeyEvent = .char(.hash)
    public static let dollar: AltKeyEvent = .char(.dollar)
    public static let percent: AltKeyEvent = .char(.percent)
    public static let amp: AltKeyEvent = .char(.amp)
    public static let singleQuote: AltKeyEvent = .char(.singleQuote)
    public static let leftParen: AltKeyEvent = .char(.leftParen)
    public static let rightParen: AltKeyEvent = .char(.rightParen)
    public static let star: AltKeyEvent = .char(.star)
    public static let plus: AltKeyEvent = .char(.plus)
    public static let comma: AltKeyEvent = .char(.comma)
    public static let dash: AltKeyEvent = .char(.dash)
    public static let dot: AltKeyEvent = .char(.dot)
    public static let number0: AltKeyEvent = .char(.number0)
    public static let number1: AltKeyEvent = .char(.number1)
    public static let number2: AltKeyEvent = .char(.number2)
    public static let number3: AltKeyEvent = .char(.number3)
    public static let number4: AltKeyEvent = .char(.number4)
    public static let number5: AltKeyEvent = .char(.number5)
    public static let number6: AltKeyEvent = .char(.number6)
    public static let number7: AltKeyEvent = .char(.number7)
    public static let number8: AltKeyEvent = .char(.number8)
    public static let number9: AltKeyEvent = .char(.number9)
    public static let colon: AltKeyEvent = .char(.colon)
    public static let semicolon: AltKeyEvent = .char(.semicolon)
    public static let lt: AltKeyEvent = .char(.lt)
    public static let eq: AltKeyEvent = .char(.eq)
    public static let gt: AltKeyEvent = .char(.gt)
    public static let question: AltKeyEvent = .char(.question)
    public static let at: AltKeyEvent = .char(.at)
    public static let A: AltKeyEvent = .char(.A)
    public static let B: AltKeyEvent = .char(.B)
    public static let C: AltKeyEvent = .char(.C)
    public static let D: AltKeyEvent = .char(.D)
    public static let E: AltKeyEvent = .char(.E)
    public static let F: AltKeyEvent = .char(.F)
    public static let G: AltKeyEvent = .char(.G)
    public static let H: AltKeyEvent = .char(.H)
    public static let I: AltKeyEvent = .char(.I)
    public static let J: AltKeyEvent = .char(.J)
    public static let K: AltKeyEvent = .char(.K)
    public static let L: AltKeyEvent = .char(.L)
    public static let M: AltKeyEvent = .char(.M)
    public static let N: AltKeyEvent = .char(.N)
    public static let O: AltKeyEvent = .char(.O)
    public static let P: AltKeyEvent = .char(.P)
    public static let Q: AltKeyEvent = .char(.Q)
    public static let R: AltKeyEvent = .char(.R)
    public static let S: AltKeyEvent = .char(.S)
    public static let T: AltKeyEvent = .char(.T)
    public static let U: AltKeyEvent = .char(.U)
    public static let V: AltKeyEvent = .char(.V)
    public static let W: AltKeyEvent = .char(.W)
    public static let X: AltKeyEvent = .char(.X)
    public static let Y: AltKeyEvent = .char(.Y)
    public static let Z: AltKeyEvent = .char(.Z)
    public static let leftBracket: AltKeyEvent = .char(.leftBracket)
    public static let backslash: AltKeyEvent = .char(.backslash)
    public static let rightBracket: AltKeyEvent = .char(.rightBracket)
    public static let caret: AltKeyEvent = .char(.caret)
    public static let underscore: AltKeyEvent = .char(.underscore)
    public static let backtick: AltKeyEvent = .char(.backtick)
    public static let a: AltKeyEvent = .char(.a)
    public static let b: AltKeyEvent = .char(.b)
    public static let c: AltKeyEvent = .char(.c)
    public static let d: AltKeyEvent = .char(.d)
    public static let e: AltKeyEvent = .char(.e)
    public static let f: AltKeyEvent = .char(.f)
    public static let g: AltKeyEvent = .char(.g)
    public static let h: AltKeyEvent = .char(.h)
    public static let i: AltKeyEvent = .char(.i)
    public static let j: AltKeyEvent = .char(.j)
    public static let k: AltKeyEvent = .char(.k)
    public static let l: AltKeyEvent = .char(.l)
    public static let m: AltKeyEvent = .char(.m)
    public static let n: AltKeyEvent = .char(.n)
    public static let o: AltKeyEvent = .char(.o)
    public static let p: AltKeyEvent = .char(.p)
    public static let q: AltKeyEvent = .char(.q)
    public static let r: AltKeyEvent = .char(.r)
    public static let s: AltKeyEvent = .char(.s)
    public static let t: AltKeyEvent = .char(.t)
    public static let u: AltKeyEvent = .char(.u)
    public static let v: AltKeyEvent = .char(.v)
    public static let w: AltKeyEvent = .char(.w)
    public static let x: AltKeyEvent = .char(.x)
    public static let y: AltKeyEvent = .char(.y)
    public static let z: AltKeyEvent = .char(.z)
    public static let leftCurly: AltKeyEvent = .char(.leftCurly)
    public static let pipe: AltKeyEvent = .char(.pipe)
    public static let rightCurly: AltKeyEvent = .char(.rightCurly)
    public static let tilde: AltKeyEvent = .char(.tilde)
}

extension AltKeyEvent {
    public var isPrintable: Bool {
        toPrintable != ""
    }

    public var toPrintable: String {
        switch self {
        case .char(.a): return "å"
        case .char(.b): return "∫"
        case .char(.c): return "ç"
        case .char(.d): return "∂"
        case .char(.e): return "\u{F0000}"  // combining ´
        case .char(.f): return "ƒ"
        case .char(.g): return "©"
        case .char(.h): return "˙"
        case .char(.i): return "\u{F0001}"  // combining ˆ
        case .char(.j): return "∆"
        case .char(.k): return "˚"
        case .char(.l): return "¬"
        case .char(.m): return "µ"
        case .char(.n): return "\u{F0002}"  // uF0002, combining ˜
        case .char(.o): return "ø"
        case .char(.p): return "π"
        case .char(.q): return "œ"
        case .char(.r): return "®"
        case .char(.s): return "ß"
        case .char(.t): return "†"
        case .char(.u): return "\u{F0003}"  // uF0003, combining ¨
        case .char(.v): return "√"
        case .char(.w): return "∑"
        case .char(.x): return "≈"
        case .char(.y): return "¥"
        case .char(.z): return "Ω"
        case .char(.backtick): return "\u{F0004}"  // uF0004, combining `
        case .char(.number1): return "¡"
        case .char(.number2): return "™"
        case .char(.number3): return "£"
        case .char(.number4): return "¢"
        case .char(.number5): return "∞"
        case .char(.number6): return "§"
        case .char(.number7): return "¶"
        case .char(.number8): return "•"
        case .char(.number9): return "ª"
        case .char(.number0): return "º"
        case .char(.dash): return "–"
        case .char(.eq): return "≠"
        case .char(.leftBracket): return "“"
        case .char(.rightBracket): return "‘"
        case .char(.backslash): return "«"
        case .char(.semicolon): return "…"
        case .char(.singleQuote): return "æ"
        case .char(.comma): return "≤"
        case .char(.dot): return "≥"
        case .char(.slash): return "÷"
        // shifted
        case .char(.A): return "Å"
        case .char(.B): return "ı"
        case .char(.C): return "Ç"
        case .char(.D): return "Î"
        case .char(.E): return "´"
        case .char(.F): return "Ï"
        case .char(.G): return "˝"
        case .char(.H): return "Ó"
        case .char(.I): return "ˆ"
        case .char(.J): return "Ô"
        case .char(.K): return ""
        case .char(.L): return "Ò"
        case .char(.M): return "Â"
        case .char(.N): return "˜"
        case .char(.O): return "Ø"
        case .char(.P): return "∏"
        case .char(.Q): return "Œ"
        case .char(.R): return "‰"
        case .char(.S): return "Í"
        case .char(.T): return "ˇ"
        case .char(.U): return "¨"
        case .char(.V): return "◊"
        case .char(.W): return "„"
        case .char(.X): return "˛"
        case .char(.Y): return "Á"
        case .char(.Z): return "¸"
        case .char(.tilde): return "~"
        case .char(.bang): return "/"
        case .char(.at): return "€"
        case .char(.hash): return "‹"
        case .char(.dollar): return "›"
        case .char(.percent): return "ﬁ"
        case .char(.caret): return "ﬂ"
        case .char(.amp): return "‡"
        case .char(.star): return "°"
        case .char(.leftParen): return "·"
        case .char(.rightParen): return "‚"
        case .char(.underscore): return "—"
        case .char(.plus): return "±"
        case .char(.leftCurly): return "”"
        case .char(.rightCurly): return "’"
        case .char(.pipe): return "»"
        case .char(.colon): return "Ú"
        case .char(.doubleQuote): return "Æ"
        case .char(.lt): return "¯"
        case .char(.gt): return "˘"
        case .char(.question): return "¿"
        default:
            return ""
        }
    }

    public var toString: String {
        switch self {
        case let .shift(key): return "⇧\(key.toString)"
        case let .char(key): return key.toString
        case let .fn(key): return key.toString
        }
    }
}

extension AltKeyEvent: Equatable {
    public static func == (lhs: AltKeyEvent, rhs: AltKeyEvent) -> Bool {
        lhs.toString == rhs.toString
    }
}

public enum ShiftKeyEvent {
    case down
    case up
    case left
    case right
    case home
    case end
}

extension ShiftKeyEvent {
    public var toString: String {
        switch self {
        case .down: return "↓"
        case .up: return "↑"
        case .left: return "←"
        case .right: return "→"
        case .home: return "⤒"
        case .end: return "⤓"
        }
    }
}

extension ShiftKeyEvent: Equatable {
    public static func == (lhs: ShiftKeyEvent, rhs: ShiftKeyEvent) -> Bool {
        lhs.toString == rhs.toString
    }
}

public enum CharKeyEvent: UInt16 {
    case space = 32
    case bang
    case doubleQuote
    case hash
    case dollar
    case percent
    case amp
    case singleQuote
    case leftParen
    case rightParen
    case star
    case plus
    case comma
    case dash
    case dot
    case slash

    case number0
    case number1
    case number2
    case number3
    case number4
    case number5
    case number6
    case number7
    case number8
    case number9

    case colon
    case semicolon
    case lt
    case eq
    case gt
    case question
    case at

    case A
    case B
    case C
    case D
    case E
    case F
    case G
    case H
    case I
    case J
    case K
    case L
    case M
    case N
    case O
    case P
    case Q
    case R
    case S
    case T
    case U
    case V
    case W
    case X
    case Y
    case Z

    case leftBracket
    case backslash
    case rightBracket
    case caret
    case underscore
    case backtick

    case a
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z

    case leftCurly
    case pipe
    case rightCurly
    case tilde
}

extension CharKeyEvent {
    public var toPrintable: String {
        if case .space = self {
            return " "
        }
        return toString
    }

    public var toString: String {
        switch self {
        case .space: return "␣"

        case .bang: return "!"
        case .doubleQuote: return "\""
        case .hash: return "#"
        case .dollar: return "$"
        case .percent: return "%"
        case .amp: return "&"
        case .singleQuote: return "'"
        case .leftParen: return "("
        case .rightParen: return ")"
        case .star: return "*"
        case .plus: return "+"
        case .comma: return ","
        case .dash: return "-"
        case .dot: return "."
        case .slash: return "/"

        case .colon: return ":"
        case .semicolon: return ";"
        case .lt: return "<"
        case .eq: return "="
        case .gt: return ">"
        case .question: return "?"
        case .at: return "@"

        case .leftBracket: return "["
        case .backslash: return "\\"
        case .rightBracket: return "]"
        case .caret: return "^"
        case .underscore: return "_"
        case .backtick: return "`"

        case .leftCurly: return "{"
        case .pipe: return "|"
        case .rightCurly: return "}"
        case .tilde: return "~"

        case .number0: return "0"
        case .number1: return "1"
        case .number2: return "2"
        case .number3: return "3"
        case .number4: return "4"
        case .number5: return "5"
        case .number6: return "6"
        case .number7: return "7"
        case .number8: return "8"
        case .number9: return "9"

        case .A: return "A"
        case .B: return "B"
        case .C: return "C"
        case .D: return "D"
        case .E: return "E"
        case .F: return "F"
        case .G: return "G"
        case .H: return "H"
        case .I: return "I"
        case .J: return "J"
        case .K: return "K"
        case .L: return "L"
        case .M: return "M"
        case .N: return "N"
        case .O: return "O"
        case .P: return "P"
        case .Q: return "Q"
        case .R: return "R"
        case .S: return "S"
        case .T: return "T"
        case .U: return "U"
        case .V: return "V"
        case .W: return "W"
        case .X: return "X"
        case .Y: return "Y"
        case .Z: return "Z"

        case .a: return "a"
        case .b: return "b"
        case .c: return "c"
        case .d: return "d"
        case .e: return "e"
        case .f: return "f"
        case .g: return "g"
        case .h: return "h"
        case .i: return "i"
        case .j: return "j"
        case .k: return "k"
        case .l: return "l"
        case .m: return "m"
        case .n: return "n"
        case .o: return "o"
        case .p: return "p"
        case .q: return "q"
        case .r: return "r"
        case .s: return "s"
        case .t: return "t"
        case .u: return "u"
        case .v: return "v"
        case .w: return "w"
        case .x: return "x"
        case .y: return "y"
        case .z: return "z"
        }
    }
}

public enum FnKeyEvent {
    case tab
    case enter
    case esc
    case backspace
    case backtab

    case down
    case up
    case left
    case right

    case f1
    case f2
    case f3
    case f4
    case f5
    case f6
    case f7
    case f8
    case f9
    case f10
    case f11
    case f12

    case home
    case pageDown
    case pageUp
    case end
    case delete
    case insert

}

extension FnKeyEvent {
    public var toPrintable: String {
        switch self {
        case .enter:
            return "\n"
        default:
            return ""
        }
    }

    public var toString: String {
        switch self {
        case .tab: return "⇥"
        case .enter: return "↩︎"
        case .esc: return "⎋"
        case .backspace: return "⌫"
        case .backtab: return "⇤"

        case .down: return "↓"
        case .up: return "↑"
        case .left: return "←"
        case .right: return "→"

        case .f1: return "𝔽1"
        case .f2: return "𝔽2"
        case .f3: return "𝔽3"
        case .f4: return "𝔽4"
        case .f5: return "𝔽5"
        case .f6: return "𝔽6"
        case .f7: return "𝔽7"
        case .f8: return "𝔽8"
        case .f9: return "𝔽9"
        case .f10: return "𝔽10"
        case .f11: return "𝔽11"
        case .f12: return "𝔽12"

        case .home: return "⤒"
        case .pageUp: return "↟"
        case .pageDown: return "↡"
        case .end: return "⤓"
        case .delete: return "⌦"
        case .insert: return "⌅"
        }
    }
}

extension KeyEvent: CustomStringConvertible {
    public var description: String { toString }
}

extension CtrlKeyEvent: CustomStringConvertible {
    public var description: String { toString }
}

extension AltKeyEvent: CustomStringConvertible {
    public var description: String { toString }
}

extension ShiftKeyEvent: CustomStringConvertible {
    public var description: String { toString }
}

extension CharKeyEvent: CustomStringConvertible {
    public var description: String { toString }
}

extension FnKeyEvent: CustomStringConvertible {
    public var description: String { toString }
}
