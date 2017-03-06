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
    typealias CommandType = Command<MessageType>

    func initial() -> (ModelType, [CommandType])
    func update(model: inout ModelType, message: MessageType) -> (ModelType, [CommandType], LoopState)
    func render(model: ModelType, in screenSize: Size) -> Component
}
