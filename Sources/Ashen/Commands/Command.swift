////
///  Command.swift
//


protocol Command {
    func start(_ done: @escaping (AnyMessage) -> Void)
    func map<T, U>(_ mapper: @escaping (T) -> U) -> Self
}

extension Command {
    func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        return self
    }
}
