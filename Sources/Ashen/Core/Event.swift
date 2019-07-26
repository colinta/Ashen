////
///  Event.swift
//

import Darwin.ncurses
import Termbox

public enum Event {
    case key(KeyEvent)
    case mouse(Int, Int)
    case click(MouseButton)
    case window(width: Int, height: Int)
    case tick(Float)
    case log(String)
}

public enum MouseButton {
    case left
    case right
    case middle
    case release
    case wheelUp
    case wheelDown
}
