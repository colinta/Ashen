////
///  Update.swift
//

public enum Update<T> {
    case noChange
    case model(T)
    case update(T, [Command])
    case quit
    case error(Error)
    case quitAnd(() throws -> Void)

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
