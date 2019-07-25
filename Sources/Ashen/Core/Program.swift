////
///  Program.swift
//

public typealias AnyMessage = Any
public class AnyInstance { fileprivate init() {} }
public let NoMessage = AnyInstance()

public typealias AnyCommand = Any

public protocol Program {
    associatedtype ModelType
    associatedtype MessageType

    func setup(screen: ScreenType)
    func initial() -> (ModelType, [Command])
    func update(model: inout ModelType, message: MessageType) -> (ModelType, [Command], LoopState)
    func render(model: ModelType, in screenSize: Size) -> Component
}

public extension Program {
    func setup(screen: ScreenType) {
    }
}
