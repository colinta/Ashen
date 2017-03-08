////
///  SpinnersDemo.swift
//

struct SpinnersDemo: Program {
    enum Message {
        case quit
        case toggle
    }

    struct Model {
        var spinners: [SpinnerView.Model]
        var animating: Bool
    }

    func initial() -> (Model, [Command]) {
        return (Model(
            spinners: (0 ..< SpinnerView.Model.availableSpinners).map { i in
                return SpinnerView.Model(spinner: i)
            },
            animating: true
            ), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .toggle:
            model.animating = !model.animating
            return (model, [], .continue)
        case .quit:
            return (model, [], .quit)
        }
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let spinners = model.spinners.enumerated().map { (i, spinnerModel) in
            return SpinnerView(
                .middleCenter(x: 2 * i - model.spinners.count / 2),
                model: spinnerModel,
                animating: model.animating
                )
        }
        return Window(
            components: spinners + [
                OnKeyPress(.key_enter, { return Message.quit }),
                OnKeyPress(.key_space, { return Message.toggle }),
            ])
    }
}
