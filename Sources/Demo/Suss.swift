////
///  Suss.swift
//

import Darwin


struct Suss: Program {
    enum Message {
        case quit
        case submit
        case nextInput
        case prevInput
        case onChange(Model.Input, String)
    }

    struct Model {
        enum Input: Int {
            static let first: Input = .url
            static let last: Input = .url

            case url

            var next: Input { return Input(rawValue: rawValue + 1) ?? .first }
            var prev: Input { return Input(rawValue: rawValue - 1) ?? .last }
        }

        var active: Input = .url
        var url: String = "https://"

        init() {
        }
    }

    func initial() -> (Model, [Command]) {
        return (Model(), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case .submit:
            model.url = model.url + model.url
        case .nextInput:
            model.active = model.active.next
        case .prevInput:
            model.active = model.active.prev
        case let .onChange(input, value):
            switch input {
            case .url:
                model.url = value
            }
        }

        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let urlInput = InputView(
            .topLeft(x: 1, y: 1),
            text: model.url,
            isFirstResponder: model.active == .url,
            onChange: { model in
                return Message.onChange(.url, model)
            },
            onEnter: {
                return Message.submit
            })

        return Window(components: [
            OnKeyPress(.key_esc, { return Message.quit }),
            OnKeyPress(.key_tab, { return Message.nextInput }),
            OnKeyPress(.key_backtab, { return Message.prevInput }),
            urlInput,
        ])
    }
}
