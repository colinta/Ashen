public enum KeyEvent: UInt16 {
    case signalCtrlAt = 0        // @
    case signalCtrlA             // a
    case signalCtrlB             // b
    case signalCtrlC             // c
    case signalCtrlD             // d
    case signalCtrlE             // e
    case signalCtrlF             // f
    case signalCtrlG             // g
    case signalCtrlH      // ???
    case keyTab                   // i == tab
    case signalCtrlJ             // j
    case signalCtrlK             // k
    case signalCtrlL             // l
    case keyEnter                 // m == enter
    case signalCtrlN             // n
    case signalCtrlO             // o
    case signalCtrlP             // p
    case signalCtrlQ             // q
    case signalCtrlR             // r
    case signalCtrlS             // s
    case signalCtrlT             // t
    case signalCtrlU             // u
    case signalCtrlV             // v
    case signalCtrlW             // w
    case signalCtrlX             // x
    case signalCtrlY             // y
    case signalCtrlZ             // z
    case keyEsc                   // [ == ESC
    case signalCtrlBslash        // \
    case signalCtrlRbracket      // ]
    case signalCtrlCaret         // ^
    case signalCtrlFslash        // / or -

    case keySpace = 32
    case symbolBang
    case symbolDquot
    case symbolHash
    case symbolDollar
    case symbolPercent
    case symbolAmp
    case symbolSquot
    case symbolLparen
    case symbolRparen
    case symbolStar
    case symbolPlus
    case symbolComma
    case symbolDash
    case symbolPeriod
    case symbolFslash

    case number0 = 48
    case number1
    case number2
    case number3
    case number4
    case number5
    case number6
    case number7
    case number8
    case number9

    case symbolColon = 58
    case symbolSemicolon
    case symbolLt
    case symbolEq
    case symbolGt
    case symbolQuestion
    case symbolAt

    case A = 65
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

    case symbolLbracket = 91
    case symbolBslash
    case symbolRbracket
    case symbolCaret
    case symbolUnderscore
    case symbolBacktick

    case a = 97
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

    case symbolLcurly = 123
    case symbolPipe
    case symbolRcurly
    case symbolTilde

    case keyBackspace = 0x7f
    case keyBacktab

    case keyDown
    case keyUp
    case keyLeft
    case keyRight
    case keyHome
    case keyShiftDown
    case keyShiftUp
    case keyShiftLeft
    case keyShiftRight
    case keyAltDown
    case keyAltUp
    case keyAltLeft
    case keyAltRight

    case signalCtrlHBroken        // what is this?  ^h sends it?
    case signalAltBslash

    case keyF1
    case keyF2
    case keyF3
    case keyF4
    case keyF5
    case keyF6
    case keyF7
    case keyF8
    case keyF9
    case keyF10
    case keyF11
    case keyF12

    case keyPagedown
    case keyPageup
    case keyEnd
    case keyShiftHome
    case keyShiftEnd

    case keyDelete
    case keyInsert
    case signalCtrl6

    case unrecognized = 0xffff

    // any signals that have common unix meaning are
    // named after that signal
    // (eg C-c int, C-t info, C-z suspend, C-\ quit)
    //
    // the rest are named after ASCII codes from http://www.ascii-code.com
    public static let signalNul: KeyEvent = .signalCtrlAt
    public static let signalSoh: KeyEvent = .signalCtrlA
    public static let signalStx: KeyEvent = .signalCtrlB
    public static let signalInt: KeyEvent = .signalCtrlC
    public static let signalEot: KeyEvent = .signalCtrlD
    public static let signalEnq: KeyEvent = .signalCtrlE
    public static let signalAck: KeyEvent = .signalCtrlF
    public static let signalBel: KeyEvent = .signalCtrlG
    public static let signalBs: KeyEvent = .signalCtrlHBroken
    public static let signalLf: KeyEvent = .signalCtrlJ
    public static let signalVt: KeyEvent = .signalCtrlK
    public static let signalFf: KeyEvent = .signalCtrlL
    public static let signalSo: KeyEvent = .signalCtrlN
    public static let signalDiscard: KeyEvent = .signalCtrlO
    public static let signalDle: KeyEvent = .signalCtrlP
    public static let signalStart: KeyEvent = .signalCtrlQ
    public static let signalReprint: KeyEvent = .signalCtrlR
    public static let signalStop: KeyEvent = .signalCtrlS
    public static let signalInfo: KeyEvent = .signalCtrlT
    public static let signalKill: KeyEvent = .signalCtrlU
    public static let signalNext: KeyEvent = .signalCtrlV
    public static let signalEtb: KeyEvent = .signalCtrlW
    public static let signalCancel: KeyEvent = .signalCtrlX
    public static let signalDsusp: KeyEvent = .signalCtrlY
    public static let signalSuspend: KeyEvent = .signalCtrlZ
    public static let signalQuit: KeyEvent = .signalCtrlBslash
    public static let signalGs: KeyEvent = .signalCtrlRbracket
    public static let signalRs: KeyEvent = .signalCtrlCaret
    public static let signalUs: KeyEvent = .signalCtrlFslash
    public static let signalH: KeyEvent = .signalCtrlH
}

public extension KeyEvent {
    var isPrintable: Bool {
        return self.rawValue >= 32 && self.rawValue < 127
    }

    var toString: String {
        switch self {
        case .signalCtrlAt: return "^@"
        case .signalCtrlA: return "^A"
        case .signalCtrlB: return "^B"
        case .signalCtrlC: return "^C"
        case .signalCtrlD: return "^D"
        case .signalCtrlE: return "^E"
        case .signalCtrlF: return "^F"
        case .signalCtrlG: return "^G"
        case .signalCtrlHBroken: return "^⌫"
        case .signalCtrlJ: return "^J"
        case .signalCtrlK: return "^K"
        case .signalCtrlL: return "^L"
        case .signalCtrlN: return "^N"
        case .signalCtrlO: return "^O"
        case .signalCtrlP: return "^P"
        case .signalCtrlQ: return "^Q"
        case .signalCtrlR: return "^R"
        case .signalCtrlS: return "^S"
        case .signalCtrlT: return "^T"
        case .signalCtrlU: return "^U"
        case .signalCtrlV: return "^V"
        case .signalCtrlW: return "^W"
        case .signalCtrlX: return "^X"
        case .signalCtrlY: return "^Y"
        case .signalCtrlZ: return "^Z"
        case .signalCtrlBslash: return "^\\"
        case .signalAltBslash: return "⌥\\"
        case .signalCtrlRbracket: return "^]"
        case .signalCtrlCaret: return "^^"
        case .signalCtrlFslash: return "^/"
        case .signalCtrlH: return "^H"

        case .keyBacktab: return "\\T"
        case .keyEsc: return "\\["

        case .keyBackspace: return "⌫"
        case .keyDelete: return "⌦"
        case .keyInsert: return "⌅"
        case .signalCtrl6: return "^6"

        case .keyDown: return "↓"
        case .keyUp: return "↑"
        case .keyLeft: return "←"
        case .keyRight: return "→"

        case .keyShiftDown: return "⇧↓"
        case .keyShiftUp: return "⇧↑"
        case .keyShiftLeft: return "⇧←"
        case .keyShiftRight: return "⇧→"

        case .keyAltDown: return "⌥↓"
        case .keyAltUp: return "⌥↑"
        case .keyAltLeft: return "⌥←"
        case .keyAltRight: return "⌥→"

        case .keyHome: return "⤒"
        case .keyPageup: return "↟"
        case .keyPagedown: return "↡"
        case .keyEnd: return "⤓"
        case .keyShiftHome: return "⇧⤒"
        case .keyShiftEnd: return "⇧⤓"

        case .keyF1: return "𝑓1"
        case .keyF2: return "𝑓2"
        case .keyF3: return "𝑓3"
        case .keyF4: return "𝑓4"
        case .keyF5: return "𝑓5"
        case .keyF6: return "𝑓6"
        case .keyF7: return "𝑓7"
        case .keyF8: return "𝑓8"
        case .keyF9: return "𝑓9"
        case .keyF10: return "𝑓10"
        case .keyF11: return "𝑓11"
        case .keyF12: return "𝑓12"

        // printables:

        case .keyTab: return "\t"
        case .keyEnter: return "\n"
        case .keySpace: return " "

        case .symbolBang: return "!"
        case .symbolDquot: return "\""
        case .symbolHash: return "#"
        case .symbolDollar: return "$"
        case .symbolPercent: return "%"
        case .symbolAmp: return "&"
        case .symbolSquot: return "'"
        case .symbolLparen: return "("
        case .symbolRparen: return ")"
        case .symbolStar: return "*"
        case .symbolPlus: return "+"
        case .symbolComma: return ","
        case .symbolDash: return "-"
        case .symbolPeriod: return "."
        case .symbolFslash: return "/"

        case .symbolColon: return ":"
        case .symbolSemicolon: return ";"
        case .symbolLt: return "<"
        case .symbolEq: return "="
        case .symbolGt: return ">"
        case .symbolQuestion: return "?"
        case .symbolAt: return "@"

        case .symbolLbracket: return "["
        case .symbolBslash: return "\\"
        case .symbolRbracket: return "]"
        case .symbolCaret: return "^"
        case .symbolUnderscore: return "_"
        case .symbolBacktick: return "`"

        case .symbolLcurly: return "{"
        case .symbolPipe: return "|"
        case .symbolRcurly: return "}"
        case .symbolTilde: return "~"

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

        case .unrecognized: return "⸮"
        }
    }
}
