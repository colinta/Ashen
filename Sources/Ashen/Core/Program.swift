////
///  Program.swift
//

public typealias InitialFunction<Model, Msg> = () -> Initial<Model, Msg>
public typealias UpdateFunction<Model, Msg> = (inout Model, Msg) -> State<Model, Msg>
public typealias ViewFunction<Model, Msg> = (Model, Size) -> View<Msg>

public struct Program<Model, Msg> {
    public let initial: InitialFunction<Model, Msg>
    public let update: UpdateFunction<Model, Msg>
    public let view: ViewFunction<Model, Msg>

    public init(
        _ initial: @escaping InitialFunction<Model, Msg>,
        _ update: @escaping UpdateFunction<Model, Msg>,
        _ view: @escaping ViewFunction<Model, Msg>
    ) {
        self.initial = initial
        self.update = update
        self.view = view
    }
}
