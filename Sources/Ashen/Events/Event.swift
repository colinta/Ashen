////
///  Event.swift
//

public typealias SimpleEvent<Msg> = () -> Msg

public enum Event {
    case key(KeyEvent)
    case mouse(MouseEvent)
    case window(width: Int, height: Int)
    case tick(Double)
    case log(String)
    case redraw
    case ignore
}
