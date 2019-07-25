public enum KeyEvent: UInt16 {
    case signal_ctrl_at = 0        // @
    case signal_ctrl_a = 1         // a
    case signal_ctrl_b = 2         // b
    case signal_ctrl_c = 3         // c
    case signal_ctrl_d = 4         // d
    case signal_ctrl_e = 5         // e
    case signal_ctrl_f = 6         // f
    case signal_ctrl_g = 7         // g
    case signal_ctrl_h_broken = 8  // ???
    case key_tab = 9               // i == tab
    case signal_ctrl_j = 10        // j
    case signal_ctrl_k = 11        // k
    case signal_ctrl_l = 12        // l
    case key_enter = 13            // m == enter
    case signal_ctrl_n = 14        // n
    case signal_ctrl_o = 15        // o
    case signal_ctrl_p = 16        // p
    case signal_ctrl_q = 17        // q
    case signal_ctrl_r = 18        // r
    case signal_ctrl_s = 19        // s
    case signal_ctrl_t = 20        // t
    case signal_ctrl_u = 21        // u
    case signal_ctrl_v = 22        // v
    case signal_ctrl_w = 23        // w
    case signal_ctrl_x = 24        // x
    case signal_ctrl_y = 25        // y
    case signal_ctrl_z = 26        // z
    case key_esc = 27              // [ == ESC
    case signal_ctrl_bslash = 28   // \
    case signal_ctrl_rbracket = 29 // ]
    case signal_ctrl_caret = 30    // ^
    case signal_ctrl_fslash = 31   // / or -
    case key_space = 32

    case symbol_bang = 33
    case symbol_dquot
    case symbol_hash
    case symbol_dollar
    case symbol_percent
    case symbol_amp
    case symbol_squot
    case symbol_lparen
    case symbol_rparen
    case symbol_star
    case symbol_plus
    case symbol_comma
    case symbol_dash
    case symbol_period
    case symbol_fslash

    case number_0 = 48
    case number_1
    case number_2
    case number_3
    case number_4
    case number_5
    case number_6
    case number_7
    case number_8
    case number_9

    case symbol_colon = 58
    case symbol_semicolon
    case symbol_lt
    case symbol_eq
    case symbol_gt
    case symbol_question
    case symbol_at

    case letter_A = 65
    case letter_B
    case letter_C
    case letter_D
    case letter_E
    case letter_F
    case letter_G
    case letter_H
    case letter_I
    case letter_J
    case letter_K
    case letter_L
    case letter_M
    case letter_N
    case letter_O
    case letter_P
    case letter_Q
    case letter_R
    case letter_S
    case letter_T
    case letter_U
    case letter_V
    case letter_W
    case letter_X
    case letter_Y
    case letter_Z

    case symbol_lbracket = 91
    case symbol_bslash
    case symbol_rbracket
    case symbol_caret
    case symbol_underscore
    case symbol_backtick

    case letter_a = 97
    case letter_b
    case letter_c
    case letter_d
    case letter_e
    case letter_f
    case letter_g
    case letter_h
    case letter_i
    case letter_j
    case letter_k
    case letter_l
    case letter_m
    case letter_n
    case letter_o
    case letter_p
    case letter_q
    case letter_r
    case letter_s
    case letter_t
    case letter_u
    case letter_v
    case letter_w
    case letter_x
    case letter_y
    case letter_z

    case symbol_lcurly = 123
    case symbol_pipe
    case symbol_rcurly
    case symbol_tilde

    case key_backspace = 127

    case key_backtab = 353

    case key_down = 258
    case key_up
    case key_left
    case key_right
    case key_home = 262
    case signal_ctrl_h = 263  // what is this?  ^h sends it? 263

    case key_shift_down = 336
    case key_shift_up = 337
    case key_shift_left = 393
    case key_shift_right = 402

    case key_f1 = 265
    case key_f2
    case key_f3
    case key_f4
    case key_f5
    case key_f6
    case key_f7
    case key_f8
    case key_f9
    case key_f10
    case key_f11
    case key_f12

    case key_pagedown = 338
    case key_pageup = 339
    case key_end = 360

    case key_delete
    case key_insert
    case signal_ctrl_6

    case unrecognized = 0xffff

    // any signals that have common unix meaning are
    // named after that signal
    // (eg C-c int, C-t info, C-z suspend, C-\ quit)
    //
    // the rest are named after ASCII codes from http://www.ascii-code.com
    public static let signal_nul: KeyEvent = .signal_ctrl_at
    public static let signal_soh: KeyEvent = .signal_ctrl_a
    public static let signal_stx: KeyEvent = .signal_ctrl_b
    public static let signal_int: KeyEvent = .signal_ctrl_c
    public static let signal_eot: KeyEvent = .signal_ctrl_d
    public static let signal_enq: KeyEvent = .signal_ctrl_e
    public static let signal_ack: KeyEvent = .signal_ctrl_f
    public static let signal_bel: KeyEvent = .signal_ctrl_g
    public static let signal_bs: KeyEvent = .signal_ctrl_h_broken
    public static let signal_lf: KeyEvent = .signal_ctrl_j
    public static let signal_vt: KeyEvent = .signal_ctrl_k
    public static let signal_ff: KeyEvent = .signal_ctrl_l
    public static let signal_so: KeyEvent = .signal_ctrl_n
    public static let signal_discard: KeyEvent = .signal_ctrl_o
    public static let signal_dle: KeyEvent = .signal_ctrl_p
    public static let signal_start: KeyEvent = .signal_ctrl_q
    public static let signal_reprint: KeyEvent = .signal_ctrl_r
    public static let signal_stop: KeyEvent = .signal_ctrl_s
    public static let signal_info: KeyEvent = .signal_ctrl_t
    public static let signal_kill: KeyEvent = .signal_ctrl_u
    public static let signal_next: KeyEvent = .signal_ctrl_v
    public static let signal_etb: KeyEvent = .signal_ctrl_w
    public static let signal_cancel: KeyEvent = .signal_ctrl_x
    public static let signal_dsusp: KeyEvent = .signal_ctrl_y
    public static let signal_suspend: KeyEvent = .signal_ctrl_z
    public static let signal_quit: KeyEvent = .signal_ctrl_bslash
    public static let signal_gs: KeyEvent = .signal_ctrl_rbracket
    public static let signal_rs: KeyEvent = .signal_ctrl_caret
    public static let signal_us: KeyEvent = .signal_ctrl_fslash
    public static let signal_h: KeyEvent = .signal_ctrl_h
}

public extension KeyEvent {
    var isPrintable: Bool {
        return self.rawValue >= 32 && self.rawValue < 127
    }

    var toString: String {
        switch self {
        case .signal_ctrl_at: return "^@"
        case .signal_ctrl_a: return "^A"
        case .signal_ctrl_b: return "^B"
        case .signal_ctrl_c: return "^C"
        case .signal_ctrl_d: return "^D"
        case .signal_ctrl_e: return "^E"
        case .signal_ctrl_f: return "^F"
        case .signal_ctrl_g: return "^G"
        case .signal_ctrl_h_broken: return "^⌫"
        case .signal_ctrl_j: return "^J"
        case .signal_ctrl_k: return "^K"
        case .signal_ctrl_l: return "^L"
        case .signal_ctrl_n: return "^N"
        case .signal_ctrl_o: return "^O"
        case .signal_ctrl_p: return "^P"
        case .signal_ctrl_q: return "^Q"
        case .signal_ctrl_r: return "^R"
        case .signal_ctrl_s: return "^S"
        case .signal_ctrl_t: return "^T"
        case .signal_ctrl_u: return "^U"
        case .signal_ctrl_v: return "^V"
        case .signal_ctrl_w: return "^W"
        case .signal_ctrl_x: return "^X"
        case .signal_ctrl_y: return "^Y"
        case .signal_ctrl_z: return "^Z"
        case .signal_ctrl_bslash: return "^\\"
        case .signal_ctrl_rbracket: return "^]"
        case .signal_ctrl_caret: return "^^"
        case .signal_ctrl_fslash: return "^/"
        case .signal_ctrl_h: return "^H"

        case .key_backtab: return "\\T"
        case .key_esc: return "\\["

        case .key_backspace: return "⌫"
        case .key_delete: return "⌦"
        case .key_insert: return "⌅"
        case .signal_ctrl_6: return "^6"

        case .key_down: return "↓"
        case .key_up: return "↑"
        case .key_left: return "←"
        case .key_right: return "→"

        case .key_shift_down: return "⇧↓"
        case .key_shift_up: return "⇧↑"
        case .key_shift_left: return "⇧←"
        case .key_shift_right: return "⇧→"

        case .key_home: return "⤒"
        case .key_pageup: return "↟"
        case .key_pagedown: return "↡"
        case .key_end: return "⤓"

        case .key_f1: return "𝑓1"
        case .key_f2: return "𝑓2"
        case .key_f3: return "𝑓3"
        case .key_f4: return "𝑓4"
        case .key_f5: return "𝑓5"
        case .key_f6: return "𝑓6"
        case .key_f7: return "𝑓7"
        case .key_f8: return "𝑓8"
        case .key_f9: return "𝑓9"
        case .key_f10: return "𝑓10"
        case .key_f11: return "𝑓11"
        case .key_f12: return "𝑓12"

        // printables:

        case .key_tab: return "\t"
        case .key_enter: return "\n"
        case .key_space: return " "

        case .symbol_bang: return "!"
        case .symbol_dquot: return "\""
        case .symbol_hash: return "#"
        case .symbol_dollar: return "$"
        case .symbol_percent: return "%"
        case .symbol_amp: return "&"
        case .symbol_squot: return "'"
        case .symbol_lparen: return "("
        case .symbol_rparen: return ")"
        case .symbol_star: return "*"
        case .symbol_plus: return "+"
        case .symbol_comma: return ","
        case .symbol_dash: return "-"
        case .symbol_period: return "."
        case .symbol_fslash: return "/"

        case .symbol_colon: return ":"
        case .symbol_semicolon: return ";"
        case .symbol_lt: return "<"
        case .symbol_eq: return "="
        case .symbol_gt: return ">"
        case .symbol_question: return "?"
        case .symbol_at: return "@"

        case .symbol_lbracket: return "["
        case .symbol_bslash: return "\\"
        case .symbol_rbracket: return "]"
        case .symbol_caret: return "^"
        case .symbol_underscore: return "_"
        case .symbol_backtick: return "`"

        case .symbol_lcurly: return "{"
        case .symbol_pipe: return "|"
        case .symbol_rcurly: return "}"
        case .symbol_tilde: return "~"

        case .number_0: return "0"
        case .number_1: return "1"
        case .number_2: return "2"
        case .number_3: return "3"
        case .number_4: return "4"
        case .number_5: return "5"
        case .number_6: return "6"
        case .number_7: return "7"
        case .number_8: return "8"
        case .number_9: return "9"

        case .letter_A: return "A"
        case .letter_B: return "B"
        case .letter_C: return "C"
        case .letter_D: return "D"
        case .letter_E: return "E"
        case .letter_F: return "F"
        case .letter_G: return "G"
        case .letter_H: return "H"
        case .letter_I: return "I"
        case .letter_J: return "J"
        case .letter_K: return "K"
        case .letter_L: return "L"
        case .letter_M: return "M"
        case .letter_N: return "N"
        case .letter_O: return "O"
        case .letter_P: return "P"
        case .letter_Q: return "Q"
        case .letter_R: return "R"
        case .letter_S: return "S"
        case .letter_T: return "T"
        case .letter_U: return "U"
        case .letter_V: return "V"
        case .letter_W: return "W"
        case .letter_X: return "X"
        case .letter_Y: return "Y"
        case .letter_Z: return "Z"

        case .letter_a: return "a"
        case .letter_b: return "b"
        case .letter_c: return "c"
        case .letter_d: return "d"
        case .letter_e: return "e"
        case .letter_f: return "f"
        case .letter_g: return "g"
        case .letter_h: return "h"
        case .letter_i: return "i"
        case .letter_j: return "j"
        case .letter_k: return "k"
        case .letter_l: return "l"
        case .letter_m: return "m"
        case .letter_n: return "n"
        case .letter_o: return "o"
        case .letter_p: return "p"
        case .letter_q: return "q"
        case .letter_r: return "r"
        case .letter_s: return "s"
        case .letter_t: return "t"
        case .letter_u: return "u"
        case .letter_v: return "v"
        case .letter_w: return "w"
        case .letter_x: return "x"
        case .letter_y: return "y"
        case .letter_z: return "z"

        case .unrecognized: return "<?>"
        }
    }
}
