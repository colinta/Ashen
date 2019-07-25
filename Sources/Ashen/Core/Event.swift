////
///  Event.swift
//

import Darwin.ncurses
import Termbox

public enum Event {
    case key(KeyEvent)
    case mouse(Int, Int)
    case window(width: Int, height: Int)
    case tick(Float)
    case log(String)
}
