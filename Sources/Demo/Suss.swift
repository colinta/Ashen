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
            static let last: Input = .respBody

            case url
            case httpMethod
            case parameters
            case body
            case headers
            case respHeaders
            case respBody

            var next: Input { return Input(rawValue: rawValue + 1) ?? .first }
            var prev: Input { return Input(rawValue: rawValue - 1) ?? .last }
        }

        var active: Input = .url
        var url: String = "https://"
        var httpMethod: String = "GET"
        var parameters: String = ""
        var body: String = ""
        var headers: String = ""

        var status: String { return "[Suss v1.0.0]"}

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
            case .body:
                model.body = value
            case .parameters:
                model.parameters = value
            case .headers:
                model.headers = value
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

        let httpMethods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
        let activeAttrs: [Attr]
        if model.active == .httpMethod {
            activeAttrs = [.reverse]
        }
        else {
            activeAttrs = [.underline]
        }

        let httpMethodText: [TextType] = httpMethods.map { httpMethod -> Text in
            return Text(httpMethod, attrs: httpMethod == model.httpMethod ? activeAttrs : [])
        }.reduce([TextType]()) { (memo, httpMethodText) -> [TextType] in
            if memo.count > 0 {
                return memo + [" ", httpMethodText]
            }
            else {
                return [httpMethodText]
            }
        }
        let httpMethodInputs: [Component]
        if model.active == .httpMethod {
            httpMethodInputs = [
                LabelView(text: AttrText(httpMethodText)),
                OnKeyPress(.key_left, { return Message.prevMethod }),
                OnKeyPress(.key_right, { return Message.nextMethod }),
            ]
        }
        else {
            httpMethodInputs = [LabelView(text: AttrText(httpMethodText))]
        }

        let urlLabel = Text("URL", attrs: (model.active == .url ? [.reverse] : []))

        let methodLabel = Text("Method", attrs: (model.active == .httpMethod ? [.reverse] : []))

        let requestBodyLabel = Text("POST Body", attrs: (model.active == .body ? [.reverse] : []))
        let bodyInput = InputView(
            text: model.body,
            isFirstResponder: model.active == .body,
            isMultiline: true,
            onChange: { model in
                return Message.onChange(.body, model)
            })

        let requestParametersLabel = Text("GET Parameters", attrs: (model.active == .parameters ? [.reverse] : []))
        let parametersInput = InputView(
            text: model.parameters,
            isFirstResponder: model.active == .parameters,
            isMultiline: true,
            onChange: { model in
                return Message.onChange(.parameters, model)
            })

        let requestHeadersLabel = Text("Headers", attrs: (model.active == .headers ? [.reverse] : []))
        let headersInput = InputView(
            text: model.headers,
            isFirstResponder: model.active == .headers,
            isMultiline: true,
            onChange: { model in
                return Message.onChange(.headers, model)
            })

        let responseHeadersLabel = Text("Response headers", attrs: (model.active == .respHeaders ? [.reverse] : []))
        let responseBodyLabel = Text("Response body", attrs: (model.active == .respBody ? [.reverse] : []))

        let maxSideWidth = 40
        let remainingHeight = max(screenSize.height - 8, 0)
        let requestWidth = min(maxSideWidth, screenSize.width / 3)
        let responseWidth = screenSize.width - requestWidth
        return Window(components: [
            OnKeyPress(.key_esc, { return Message.quit }),
            OnKeyPress(.key_tab, { return Message.nextInput }),
            OnKeyPress(.key_backtab, { return Message.prevInput }),
            Box(.topLeft(x: 0, y: 0), Size(width: screenSize.width, height: 2), border: fullBorder, label: urlLabel, components: [urlInput]),
            Box(.topLeft(x: 0, y: 3), Size(width: maxSideWidth, height: 2), border: sideBorder, label: methodLabel, components: httpMethodInputs),
            GridLayout(.topLeft(x: 0, y: 6), Size(width: requestWidth, height: remainingHeight), rows: [
                .row([Box(border: sideBorder, label: requestParametersLabel, components: [parametersInput])]),
                .row([Box(border: sideBorder, label: requestBodyLabel, components: [bodyInput])]),
                .row([Box(border: sideBorder, label: requestHeadersLabel, components: [headersInput])]),
            ]),
            GridLayout(.topLeft(x: requestWidth, y: 6), Size(width: responseWidth, height: remainingHeight), rows: [
                .row(weight: .fixed(10), [Box(border: sideBorder, label: responseHeadersLabel, components: [])]),
                .row([Box(border: sideBorder, label: responseBodyLabel, components: [])]),
            ]),
            Box(.bottomRight(x: 0, y: -1), Size(width: screenSize.width, height: 1), background: Text(" ", attrs: [.reverse]), components: [LabelView(text: Text(model.status, attrs: [.reverse]))]),
        ])
    }
}
