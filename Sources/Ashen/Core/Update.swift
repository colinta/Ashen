////
///  Update.swift
//

public enum Update<T> {
    case noChange
    case update(T, [Command])
    case quit
    case quitAnd(() throws -> Void)

    static public func model(_ model: T) -> Update<T> {
        .update(model, [])
    }

    static public func error(_ error: Error) -> Update<T> {
        .quitAnd({ throw error })
    }

    public var values: (T, [Command])? {
        switch self {
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
        case let .quitAnd(closure):
            return .quitAnd(closure)
        default:
            return nil
        }
    }
}
