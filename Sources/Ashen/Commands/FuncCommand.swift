////
///  FuncCommand.swift
//


public struct FuncCommand {
    let fn: () -> AnyMessage
}

extension FuncCommand: Command {
    public init(_ fn: @escaping () -> AnyMessage) {
        self.fn = fn
    }

    public func start(_ send: @escaping (AnyMessage) -> Void) {
        let msg = fn()
        send(msg)
    }

    public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let fn = self.fn
        return FuncCommand({
            mapper(fn() as! T)
        })
    }
}
