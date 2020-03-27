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
    case update(T, [Command])
    case quit
    case error(Error)
    case quitAnd(() -> ExitState)

    public var values: (T, [Command])? {
        switch self {
        case let .model(model):
            return (model, [])
        case let .update(model, commands):
            return (model, commands)
        default:
            return nil
        }
    }

    public var exitState: AppState? {
        switch self {
        case .quit:
            return .quit
        case let .error(error):
            return .error(error)
        case let .quitAnd(closure):
            return .quitAnd(closure)
        default:
            return nil
        }
    }
}

public extension Program {
    func setup(screen: ScreenType) {
    }
}
