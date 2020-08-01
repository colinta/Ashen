////
///  Command.swift
//

public struct Command<Msg> {
    public let run: ((Msg) -> Void) -> Void

    public init(_ run: @escaping ((Msg) -> Void) -> Void) {
        self.run = run
    }

    public func map<U>(_ msgMap: @escaping (Msg) -> U) -> Command<U> {
        let run = self.run
        return Command<U> { queue in
            run { msg in
                queue(msgMap(msg))
            }
        }
    }
}
