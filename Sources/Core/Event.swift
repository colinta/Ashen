////
///  Event.swift
//

import Darwin.ncurses

typealias MouseInfo = MEVENT

enum Event {
    case key(KeyEvent)
    case mouse(MouseEvent, MouseInfo)
    case window(width: Int, height: Int)
    case tick(Float)
    case log(String)
    case unknown(Int32)

    var code: Int32? {
        switch self {
        case let .key(event): return event.rawValue
        case let .mouse(event, _): return event.rawValue
        case .window: return WindowEvent.resize.rawValue
        case .tick: return -1
        case .log: return -2
        case .unknown: return -3
        }
    }

    init?(_ ch: Int32) {
        guard ch != ERR else { return nil }

        if let event = KeyEvent(rawValue: ch) {
            self = .key(event)
        }
        else if let event = MouseEvent(rawValue: ch) {
            let ptr = UnsafeMutablePointer<MEVENT>.allocate(capacity: 1)
            getmouse(ptr)
            let info = ptr.pointee
            self = .mouse(event, info)
        }
        else if WindowEvent(rawValue: ch) != nil {
            self = .window(width: Int(getmaxx(stdscr)), height: Int(getmaxy(stdscr)))
        }
        else {
            self = .unknown(ch)
        }
    }
}
