////
///  Suss.swift
//

import Darwin
import Foundation


struct Suss: Program {
    enum Error: Swift.Error {
        case invalidURL
        case missingScheme
        case missingHost
        case cannotDecode
    }

    enum Message {
        case quit
        case submit
        case nextInput
        case prevInput
        case nextMethod
        case prevMethod
        case clearError
        case received(String, Http.Headers)
        case receivedError(String)
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
        var httpMethod: Http.Method = .get
        var parameters: String = ""
        var body: String = ""
        var headers: String = ""

        var httpCommand: Http?
        var requestSent: Bool { return httpCommand != nil }

        var response: (content: String, headers: Http.Headers)?

        var error: String?
        var status: String {
            return "[Suss v1.0.0]"
        }

        var nextMethod: Http.Method {
            switch httpMethod {
            case .get: return .post
            case .post: return .put
            case .put: return .patch
            case .patch: return .delete
            case .delete: return .head
            case .head: return .options
            default: return .get
            }
        }
        var prevMethod: Http.Method {
            switch httpMethod {
            case .post: return .get
            case .put: return .post
            case .patch: return .put
            case .delete: return .patch
            case .head: return .delete
            case .options: return .head
            default: return .options
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
            do {
               return try submit(model: &model, message: message)
            }
            catch {
                model.error = (error as? Error)?.description
                return (model, [], .continue)
            }
        case let .received(response, headers):
            model.httpCommand = nil
            model.response = (content: response, headers: headers)
        case let .receivedError(error):
            model.httpCommand = nil
            model.error = error
        case .nextInput:
            model.active = model.active.next
        case .prevInput:
            model.active = model.active.prev
        case .nextMethod:
            model.httpMethod = model.nextMethod
        case .prevMethod:
            model.httpMethod = model.prevMethod
        case .clearError:
            model.error = nil
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

    func submit(model: inout Model, message: Message) throws
        -> (Model, [Command], LoopState)
    {
        var urlString = model.url

        let parameters = split(model.parameters, separator: "\n")

        if parameters.count > 0 {
            if !urlString.characters.contains("?") {
                urlString += "?"
            }
            urlString += parameters.map { param -> String in
                let parts = split(param, separator: "=", limit: 2)
                return parts.map({ part in
                    part.addingPercentEncoding(withAllowedCharacters: CharacterSet.letters) ?? part
                }).joined(separator: "=")
            }.joined(separator: "&")
        }

        let headers: Http.Headers = split(model.parameters, separator: "\n").flatMap({ entries -> Http.Header? in
            let kvp = split(entries, separator: ":", limit: 2, trim: true)
            guard kvp.count == 2 else { return nil }
            return (kvp[0], kvp[1])
        })

        guard let url = URL(string: model.url) else { throw Error.invalidURL }
        guard url.scheme != nil else { throw Error.missingScheme }
        guard url.host != nil else { throw Error.missingHost }

        let cmd = Http(url: url, options: [
            .method(model.httpMethod),
            .headers(headers)
        ]) { result in
            do {
                let (response, headers) = try result.map { data, headers -> (String, Http.Headers) in
                    if let str = String(data: data, encoding: .utf8) {
                        return (str, headers)
                    }
                    throw Error.cannotDecode
                }.unwrap()
                return Message.received(response, headers)
            }
            catch {
                let errorDescription = (error as? Error)?.description ?? "Unknown error"
                return Message.receivedError(errorDescription)
            }
        }

        model.httpCommand = cmd
        return (model, [cmd], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let activeInput: Model.Input?
        if model.error != nil || model.requestSent {
            activeInput = nil
        }
        else {
            activeInput = model.active
        }

        let urlInput = InputView(
            text: model.url,
            isFirstResponder: activeInput == .url,
            onChange: { model in
                return Message.onChange(.url, model)
            },
            onEnter: {
                return Message.submit
            })

        let httpMethods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
        let activeAttrs: [Attr]
        if activeInput == .httpMethod {
            activeAttrs = [.reverse]
        }
        else {
            activeAttrs = [.underline]
        }

        let httpMethodText: [TextType] = httpMethods.map { httpMethod -> Text in
            return Text(httpMethod, attrs: httpMethod == model.httpMethod.rawValue ? activeAttrs : [])
        }.reduce([TextType]()) { (memo, httpMethodText) -> [TextType] in
            if memo.count > 0 {
                return memo + [" ", httpMethodText]
            }
            else {
                return [httpMethodText]
            }
        }
        let httpMethodInputs: [Component]
        if activeInput == .httpMethod {
            httpMethodInputs = [
                LabelView(text: AttrText(httpMethodText)),
                OnKeyPress(.key_left, { return Message.prevMethod }),
                OnKeyPress(.key_right, { return Message.nextMethod }),
                OnKeyPress(.key_enter, { return Message.submit }),
            ]
        }
        else {
            httpMethodInputs = [LabelView(text: AttrText(httpMethodText))]
        }

        let urlLabel = Text("URL", attrs: (activeInput == .url ? [.reverse] : []))

        let methodLabel = Text("Method", attrs: (activeInput == .httpMethod ? [.reverse] : []))

        let requestBodyLabel = Text("POST Body", attrs: (activeInput == .body ? [.reverse] : []))
        let bodyInput = InputView(
            text: model.body,
            isFirstResponder: activeInput == .body,
            isMultiline: true,
            onChange: { model in
                return Message.onChange(.body, model)
            })

        let requestParametersLabel = Text("GET Parameters", attrs: (activeInput == .parameters ? [.reverse] : []))
        let parametersInput = InputView(
            text: model.parameters,
            isFirstResponder: activeInput == .parameters,
            isMultiline: true,
            onChange: { model in
                return Message.onChange(.parameters, model)
            })

        let requestHeadersLabel = Text("Headers", attrs: (activeInput == .headers ? [.reverse] : []))
        let headersInput = InputView(
            text: model.headers,
            isFirstResponder: activeInput == .headers,
            isMultiline: true,
            onChange: { model in
                return Message.onChange(.headers, model)
            })

        let responseHeadersLabel = Text("Response headers", attrs: (activeInput == .respHeaders ? [.reverse] : []))
        let responseBodyLabel = Text("Response body", attrs: (activeInput == .respBody ? [.reverse] : []))

        let maxSideWidth = 40
        let remainingHeight = max(screenSize.height - 8, 0)
        let responseHeight = max(screenSize.height - 5, 0)
        let requestWidth = min(maxSideWidth, screenSize.width / 3)
        let responseWidth = screenSize.width - requestWidth

        let topLevelComponents: [Component]
        if let error = model.error {
            topLevelComponents = [
                OnKeyPress({ _ in return Message.clearError }),
                Box(.middleCenter(), Size(width: error.characters.count + 4, height: 5), border: .single, label: "Error", components: [
                    LabelView(.topCenter(), text: Text(error, attrs: [.color(Attr.red)])),
                    LabelView(.bottomCenter(), text: Text("< OK >", attrs: [.reverse])),
                ]),
            ]
        }
        else if model.requestSent {
            topLevelComponents = [
                SpinnerView(.bottomLeft())
            ]
        }
        else {
            topLevelComponents = [
                OnKeyPress(.key_esc, { return Message.quit }),
                OnKeyPress(.key_tab, { return Message.nextInput }),
                OnKeyPress(.key_backtab, { return Message.prevInput }),
            ]
        }

        let responseHeaders: [Component]
        let responseContent: [Component]
        if let response = model.response {
            var headerString = AttrText()
            response.headers.forEach { key, value in
                headerString.append(Text(key, attrs: [.bold]))
                headerString.append(": \(value)\n")
            }
            responseHeaders = [LabelView(text: headerString)]
            responseContent = [LabelView(text: response.content)]
        }
        else {
            responseHeaders = []
            responseContent = []
        }

        return Window(components: [
            Box(.topLeft(x: 0, y: 0), Size(width: screenSize.width, height: 2), border: fullBorder, label: urlLabel, components: [urlInput]),
            Box(.topLeft(x: 0, y: 3), Size(width: maxSideWidth, height: 2), border: sideBorder, label: methodLabel, components: httpMethodInputs),
            GridLayout(.topLeft(x: 0, y: 6), Size(width: requestWidth, height: remainingHeight), rows: [
                .row([Box(border: sideBorder, label: requestParametersLabel, components: [parametersInput])]),
                .row([Box(border: sideBorder, label: requestBodyLabel, components: [bodyInput])]),
                .row([Box(border: sideBorder, label: requestHeadersLabel, components: [headersInput])]),
            ]),
            GridLayout(.topLeft(x: requestWidth, y: 3), Size(width: responseWidth, height: responseHeight), rows: [
                .row(weight: .fixed(10), [Box(border: sideBorder, label: responseHeadersLabel, components: responseHeaders)]),
                .row([Box(border: sideBorder, label: responseBodyLabel, components: responseContent)]),
            ]),
            Box(.bottomRight(x: 0, y: -1), Size(width: screenSize.width, height: 1), background: Text(" ", attrs: [.reverse]), components: [LabelView(text: Text(model.status, attrs: [.reverse]))]),
        ] + topLevelComponents)
    }
}

extension Suss.Error {
    var description: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .missingScheme: return "URL scheme is required"
        case .missingHost: return "URL host is required"
        case .cannotDecode: return "Cannot print response"
        }
    }
}

private func split(_ string: String, separator: Character, limit: Int? = nil, trim: Bool = false) -> [String] {
    guard limit != 0 else { return [] }

    var count = 1
    return string.characters.split(whereSeparator: { c -> Bool in
        guard c == separator else { return false }
        guard let limit = limit, count < limit else { return false }
        count += 1
        return true
    }).filter({ $0.count > 0 }).map({ chars in
        let retval = String(chars)
        if trim {
            return retval.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return retval })
}
