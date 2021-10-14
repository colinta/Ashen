////
///  Initial.swift
//

public struct Initial<Model, Msg> {
    public let model: Model
    public let command: Command<Msg>

    public init(_ model: Model, command: Command<Msg> = Command<Msg>.none()) {
        self.model = model
        self.command = command
    }

    public func map<U>(map msgMap: @escaping (Msg) -> U) -> Initial<Model, U> {
        return Initial<Model, U>(
            model,
            command: command.map(msgMap)
        )
    }
}
