////
///  HttpCommandDemo.swift
//

import Foundation


struct HttpCommandDemo: Program {
    struct Error: Swift.Error {}

    enum Message {
        case quit
        case abort
        case received(Http.HttpResult)
    }

    struct Model {
        var http: Http?
        var result: Result<String>?
    }

    func initial() -> (Model, [Command]) {
        let cmd = Http(url: URL(string: "http://www.gutenberg.org/cache/epub/1661/pg1661.txt")!) { result in
            return Message.received(result)
        }
        return (Model(http: cmd, result: nil), [
            cmd,
        ])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case let .received(result):
            model.http = nil
            model.result = result.map { (data, _) in
                if let str = String(data: data, encoding: .utf8) {
                    return str
                }
                throw Error()
            }
        case .abort:
            if let http = model.http {
                http.cancel()
            }
            model.http = nil
        }
        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let content: Component
        if case let .some(.ok(string)) = model.result {
            content = LabelView(.topLeft(), text: string)
        }
        else if case let .some(.fail(error)) = model.result {
            content = LabelView(.topLeft(), text: "\(error)")
        }
        else if model.http == nil {
            content = LabelView(.topLeft(), text: "Aborted.")
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
