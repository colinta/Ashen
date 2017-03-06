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

    func initial() -> (ModelType, [Command])
    func update(model: inout ModelType, message: MessageType) -> (ModelType, [Command], LoopState)
    func render(model: ModelType, in screenSize: Size) -> Component
}
