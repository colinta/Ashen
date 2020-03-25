////
///  FuncCommand.swift
//


public struct FuncCommand {
    let fn: () -> AnyMessage
}

extension FuncCommand: Command {
    public func start(_ done: @escaping (AnyMessage) -> Void) {
        let msg = fn()
        done(msg)
    }

    public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let fn = self.fn
        return FuncCommand {
            mapper(fn() as! T)
        }
    }
}
