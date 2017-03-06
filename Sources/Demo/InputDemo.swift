////
///  InputDemo.swift
//

struct InputDemo: Program {
    enum Message {
        case onChange(Int, InputView.Model)
        case quit
        case nextInput
        case prevInput
    }

    struct Model {
        var activeInput: Int
        var firstInput: InputView.Model
        var secondInput: InputView.Model
    }

    func initial() -> (Model, [Command]) {
        return (Model(
            activeInput: 0,
            firstInput: InputView.Model(text: "Press enter to exit, tab to switch inputs"),
            secondInput: InputView.Model.default
            ), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .nextInput:
            model.activeInput = (model.activeInput + 1) % 2
        case .prevInput:
            model.activeInput = (model.activeInput - 1) % 2
        case let .onChange(index, inputModel):
            if index == 0 {
                model.firstInput = inputModel
            }
            else {
                model.secondInput = inputModel
            }
        case .quit:
            return (model, [], .quit)
        }
        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let firstInput = InputView(
            .topLeft(x: 1, y: 1),
            model: model.firstInput,
            isFirstResponder: model.activeInput == 0,
            onChange: { model in
                return Message.onChange(0, model)
            },
            onEnter: {
                return Message.quit
            })
        let secondInput = InputView(
            .topLeft(x: 1, y: 3),
            model: model.secondInput,
            isFirstResponder: model.activeInput == 1,
            multiline: true,
            onChange: { model in
                return Message.onChange(1, model)
            })
        return Window(components: [
            firstInput,
            secondInput,
            OnKeyPress(.key_tab, { return Message.nextInput }),
            OnKeyPress(.key_backtab, { return Message.prevInput }),
        ])
    }
}
