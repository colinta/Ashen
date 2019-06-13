enum MouseEvent: Int32 {
    case any = 409
}

enum MouseCode: UInt {
    case left_up = 0x0000001
    case left_down = 0x0000002
    case left_click = 0x0000004
    case left_double_click = 0x0000008

    case right_up = 0x0000040
    case right_down = 0x0000080
    case right_click = 0x0000100
    case right_double_click = 0x0000200

    case button3_up = 0x0001000
    case button3_down = 0x0002000
    case button3_click = 0x0004000
    case button3_double_click = 0x0008000

    case button4_up = 0x0040000
    case button4_down = 0x0080000
    case button4_click = 0x0100000
    case button4_double_click = 0x0200000

    case mod_ctrl = 0x1000000
    case mod_shift = 0x2000000
    case mod_alt = 0x4000000
    case move = 0x8000000
}
