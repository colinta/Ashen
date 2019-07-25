////
///  Result.swift
//

public enum Result<T> {
    case ok(T)
    case fail(Error)

    public func map<U>(_ mapper: (T) throws -> U) -> Result<U> {
        switch self {
        case let .ok(value):
            let result: Result<U>
            do {
                result = try .ok(mapper(value))
            }
            catch {
                result = .fail(error)
            }
            return result
        case let .fail(error):
            return .fail(error)
        }
    }

    public func unwrap() throws -> T {
        switch self {
        case let .ok(value):
            return value
        case let .fail(error):
            throw error
        }
    }
}
