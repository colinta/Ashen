////
///  Result.swift
//

enum Result<T, ErrorType: Error> {
    case ok(T)
    case fail(ErrorType)

    func unwrap() throws -> T {
        switch self {
        case let .ok(value):
            return value
        case let .fail(error):
            throw error
        }
    }
}
