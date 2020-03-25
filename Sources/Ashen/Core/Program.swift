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
    func update(model: inout ModelType, message: MessageType) -> Update<ModelType>
    func render(model: ModelType, in screenSize: Size) -> Component
}

public enum Update<T> {
    case noChange
    case model(T)
    case commands([Command])
    case update(T, [Command])
    case quit
    case error
    case quitAnd(() -> ExitState)
}

public extension Program {
    func setup(screen: ScreenType) {
    }
}
