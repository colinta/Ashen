////
///  SpinnersDemo.swift
//

struct SpinnersDemo: Program {
    enum Message {
        case quit
    }

    struct Model {
        var spinners: [SpinnerView.Model]
    }

    func model() -> Model {
        return Model(spinners: (0 ..< SpinnerView.Model.availableSpinners).map { i in
            return SpinnerView.Model(spinner: i)
        })
    }

    func update(model: inout Model, message: Message)
        -> (Model, [AnyCommand], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        }
    }

    func render(model: Model, in screenSize: Size) -> ComponentType {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            return SpinnerView(.mc(x: 2 * i - model.spinners.count / 2), model: spinnerModel)
        }
        return Window(
            components: spinners + [
                OnKeyPress(.key_enter, { return Message.quit }),
            ])
    }

    func start(command: AnyCommand, done: @escaping (Message) -> Void) {
    }
}
