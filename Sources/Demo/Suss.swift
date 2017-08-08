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
        case nextMethod
        case prevMethod
        case onChange(Model.Input, String)
    }

    struct Model {
        enum Input: Int {
            static let first: Input = .url
            static let last: Input = .method

            case url
            case method

            var next: Input { return Input(rawValue: rawValue + 1) ?? .first }
            var prev: Input { return Input(rawValue: rawValue - 1) ?? .last }
        }

        var active: Input = .url
        var url: String = "https://"
        var httpMethod: String = "GET"

        var nextMethod: String {
            switch httpMethod {
            case "GET": return "POST"
            case "POST": return "PUT"
            case "PUT": return "PATCH"
            case "PATCH": return "DELETE"
            case "DELETE": return "HEAD"
            case "HEAD": return "OPTIONS"
            default: return "GET"
            }
        }
        var prevMethod: String {
            switch httpMethod {
            case "POST": return "GET"
            case "PUT": return "POST"
            case "PATCH": return "PUT"
            case "DELETE": return "PATCH"
            case "HEAD": return "DELETE"
            case "OPTIONS": return "HEAD"
            default: return "OPTIONS"
            }
        }

        init() {
        }
    }

    let fullBorder = Box.Border(
        tlCorner: "┌", trCorner: "┐", blCorner: "│", brCorner: "│",
        tbSide: "─", topSide: "─", bottomSide: "",
        lrSide: "│", leftSide: "│", rightSide: "│"
        )
    let sideBorder = Box.Border(
        tlCorner: "┌", trCorner: "─", blCorner: "│", brCorner: "",
        tbSide: "─", topSide: "─", bottomSide: "",
        lrSide: "│", leftSide: "│", rightSide: ""
        )

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
            // model.url = model.url + model.url
            break
        case .nextInput:
            model.active = model.active.next
        case .prevInput:
            model.active = model.active.prev
        case .nextMethod:
            model.httpMethod = model.nextMethod
        case .prevMethod:
            model.httpMethod = model.prevMethod
        case let .onChange(input, value):
            switch input {
            case .url:
                model.url = value
            default:
                break
            }
        }

        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let urlInput = InputView(
            text: model.url,
            isFirstResponder: model.active == .url,
            onChange: { model in
                return Message.onChange(.url, model)
            },
            onEnter: {
                return Message.submit
            })

        let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
        let activeAttrs: [Attr]
        if model.active == .method {
            activeAttrs = [.reverse]
        }
        else {
            activeAttrs = [.underline]
        }

        let methodText: [TextType] = methods.map { method -> Text in
            return Text(method, attrs: method == model.httpMethod ? activeAttrs : [])
        }.reduce([TextType]()) { (memo, methodText) -> [TextType] in
            if memo.count > 0 {
                return memo + [" ", methodText]
            }
            else {
                return [methodText]
            }
        }
        let methodInputs: [Component]
        if model.active == .method {
            methodInputs = [
                LabelView(text: AttrText(methodText)),
                OnKeyPress(.key_left, { return Message.prevMethod }),
                OnKeyPress(.key_right, { return Message.nextMethod }),
            ]
        }
        else {
            methodInputs = [LabelView(text: AttrText(methodText))]
        }

        let remainingHeight = max(screenSize.height - 8, 0)
        return Window(components: [
            OnKeyPress(.key_esc, { return Message.quit }),
            OnKeyPress(.key_tab, { return Message.nextInput }),
            OnKeyPress(.key_backtab, { return Message.prevInput }),
            Box(.topLeft(x: 0, y: 0), Size(width: screenSize.width, height: 2), border: fullBorder, components: [urlInput]),
            LabelView(.topLeft(x: 2, y: 0), text: "URL"),
            Box(.topLeft(x: 0, y: 3), Size(width: 38, height: 2), border: sideBorder, components: methodInputs),
            LabelView(.topLeft(x: 2, y: 3), text: "Method"),
            Box(.topLeft(x: 0, y: 6), Size(width: min(20, screenSize.width / 3), height: remainingHeight), border: sideBorder),
            LabelView(.topLeft(x: 2, y: 6), text: "Parameters"),
        ])
    }
}
