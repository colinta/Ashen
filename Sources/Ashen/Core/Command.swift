////
///  Command.swift
//

public struct Command<Msg> {
    public let run: (@escaping (Msg) -> Void) -> Void

    public init(_ run: @escaping (@escaping (Msg) -> Void) -> Void) {
        self.run = run
    }

    public func map<U>(_ msgMap: @escaping (Msg) -> U) -> Command<U> {
        let run = self.run
        return Command<U> { send in
            run { msg in
                send(msgMap(msg))
            }
        }
    }

    public static func none<U>() -> Command<U> {
        Command<U> { _ in }
    }

    public static func send<U>(_ message: U) -> Command<U> {
        Command<U> { send in send(message) }
    }

    public static func list<U>(_ commands: [Command<U>]) -> Command<U> {
        Command<U> { send in
            for command in commands {
                command.run(send)
            }
        }
    }
}
