////
///  Program.swift
//

import Darwin.ncurses

typealias AnyMessage = Any
struct AnyInstance {}
let NoMessage = AnyInstance()

typealias AnyCommand = Any

protocol Program {
    associatedtype ModelType
    associatedtype MessageType

    func setup(screen: ScreenType)
    func initial() -> (ModelType, [Command])
    func update(model: inout ModelType, message: MessageType) -> (ModelType, [Command], LoopState)
    func render(model: ModelType, in screenSize: Size) -> Component
}

func defaultSetup(screen: ScreenType) {
    screen.initColor(Attr.black, fg: (0, 0, 0), bg: nil)
    screen.initColor(Attr.red, fg: (1000, 0, 0), bg: nil)
    screen.initColor(Attr.green, fg: (0, 1000, 0), bg: nil)
    screen.initColor(Attr.yellow, fg: (1000, 1000, 0), bg: nil)
    screen.initColor(Attr.blue, fg: (0, 0, 1000), bg: nil)
    screen.initColor(Attr.magenta, fg: (1000, 0, 1000), bg: nil)
    screen.initColor(Attr.cyan, fg: (0, 1000, 1000), bg: nil)
    screen.initColor(Attr.white, fg: (1000, 1000, 1000), bg: nil)
}

extension Program {
    func setup(screen: ScreenType) {
        defaultSetup(screen: screen)
    }
}
