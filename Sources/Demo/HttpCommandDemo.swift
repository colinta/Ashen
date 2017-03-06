////
///  HttpCommandDemo.swift
//

import Foundation


struct HttpCommandDemo: Program {
    enum Message {
        case quit
        case arrived
    }

    struct Model {
        var loading: Bool
    }

    func initial() -> (Model, [Command<Message>]) {
        return (Model(loading: true), [
            Http<Message>(url: URL(string: "http://colinta.com")!) { _ in
                debug("done")
                return .arrived},
        ])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command<Message>], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case .arrived:
            model.loading = false
            return (model, [], .continue)
        }
    }

    func render(model: Model, in screenSize: Size) -> Component {
        return Window(
            components: [
                OnKeyPress(.key_enter, { return Message.quit }),
            ] + [model.loading ? SpinnerView(.topLeft()) : LabelView(.topLeft(), text: "☻")])
    }

    func start(command: Command<Message>, done: @escaping (Message) -> Void) {
    }
}
