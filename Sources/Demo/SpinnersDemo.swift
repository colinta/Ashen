////
///  SpinnersDemo.swift
//


struct SpinnersDemo: Program {
    enum Message {
        case quit
        case toggle
        case advanceColor(Int)
    }

    struct Model {
        var spinners: [SpinnerView.Model]
        var animating: Bool
        var color: Int?
    }

    func initial() -> (Model, [Command]) {
        return (Model(
            spinners: (0 ..< SpinnerView.Model.availableSpinners).map { i in
                return SpinnerView.Model(spinner: i)
            },
            animating: true,
            color: nil
            ), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .toggle:
            model.animating = !model.animating
        case let .advanceColor(delta):
            model.color = (model.color ?? -1) + delta
        case .quit:
            return (model, [], .quit)
        }
        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            return SpinnerView(
                .middleCenter(x: 2 * i - model.spinners.count / 2),
                model: spinnerModel,
                color: model.color,
                animating: model.animating
                )
        }
        return Window(
            components: spinners + [
                OnKeyPress(.key_enter, { return Message.quit }),
                OnKeyPress(.key_space, { return Message.toggle }),
                OnKeyPress(.key_right, { return Message.advanceColor(1) }),
                OnKeyPress(.key_left, { return Message.advanceColor(-1) }),
            ])
    }
}
