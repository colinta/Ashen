////
///  Command.swift
//


public protocol Command {
    func start(_ done: @escaping (AnyMessage) -> Void)
    func map<T, U>(_ mapper: @escaping (T) -> U) -> Self
}

extension Command {
    public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        return self
    }
}
