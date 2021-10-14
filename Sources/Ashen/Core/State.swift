////
///  State.swift
//

public enum State<Model, Msg> {
    case noChange
    case update(Model, Command<Msg>)
    case quit
    case quitAnd(() throws -> Void)

    public func map<ModelT, MsgT>(_ map: @escaping (Model, Command<Msg>)
        -> (ModelT, Command<MsgT>)
    ) -> State<ModelT, MsgT> {
        switch self {
        case .noChange:
            return .noChange
        case .quit:
            return .quit
        case let .quitAnd(run):
            return .quitAnd(run)
        case let .update(model, command):
            let (modelT, commandT) = map(model, command)
            return .update(modelT, commandT)
        }
    }

    public static func model<Model, Msg>(_ model: Model) -> State<Model, Msg> {
        .update(model, Command<Msg>.none())
    }

    public static func error<Model, Msg>(_ error: Error) -> State<Model, Msg> {
        .quitAnd({ throw error })
    }
}
