////
///  HttpCommandDemo.swift
//

import Foundation


struct HttpCommandDemo: Program {
    enum Message {
        case quit
        case received(Http.HttpResult)
    }

    struct Model {
        var result: Http.HttpResult?
        var loading: Bool { return result == nil }
    }

    func initial() -> (Model, [Command]) {
        return (Model(result: nil), [
            Http(url: URL(string: "http://colinta.com")!) { result in
                return Message.received(result)
            },
        ])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case let .received(result):
            model.result = result
            return (model, [], .continue)
        }
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let content: Component
        if case let .some(.ok(data, _)) = model.result,
            let string = String(data: data, encoding: .utf8)
        {
            content = LabelView(.topLeft(), text: string)
        }
        else if case let .some(.fail(error)) = model.result {
            content = LabelView(.topLeft(), text: "\(error)")
        }
        else {
            content = SpinnerView(.middleCenter())
        }

        return Window(
            components: [
                OnKeyPress(.key_enter, { return Message.quit }),
            ] + [content])
    }
}
