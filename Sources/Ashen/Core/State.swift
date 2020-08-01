////
///  State.swift
//

public enum State<Model, Msg> {
    case noChange
    case update(Model, [Command<Msg>])
    case quit
    case quitAnd(() throws -> Void)

    public static func model<Model, Msg>(_ model: Model) -> State<Model, Msg> {
        .update(model, [])
    }

    public static func error<Model, Msg>(_ error: Error) -> State<Model, Msg> {
        .quitAnd({ throw error })
    }
}
