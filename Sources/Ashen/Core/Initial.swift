////
///  Initial.swift
//

public struct Initial<Model, Msg> {
    public let model: Model
    public let commands: [Command<Msg>]

    public init(_ model: Model, commands: [Command<Msg>] = []) {
        self.model = model
        self.commands = commands
    }

    public func map<U>(map msgMap: @escaping (Msg) -> U) -> Initial<Model, U> {
        return Initial<Model, U>(
            model,
            commands: self.commands.map { cmd in cmd.map(msgMap) }
        )
    }
}
