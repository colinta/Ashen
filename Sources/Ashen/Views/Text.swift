////
///  Text.swift
//

public enum TextOption {
    case wrap(Bool)
}

public func Text<Msg>(_ text: Attributed, _ options: TextOption...) -> View<Msg> {
    var wrap = false
    for opt in options {
        switch opt {
        case let .wrap(wrapOpt):
            wrap = wrapOpt
        }
    }
    return View(
        preferredSize: { size in
            guard wrap else {
                return Size(width: text.maxWidth, height: text.countLines)
            }
            let withNewlines = text.insertNewlines(fitting: size.width)
            return Size(width: withNewlines.maxWidth, height: withNewlines.countLines)
        },
        render: { viewport, buffer in
            guard !viewport.isEmpty else { return }

            guard wrap else {
                return buffer.write(text, at: .zero)
            }
            let withNewlines = text.insertNewlines(fitting: viewport.size.width)
            buffer.write(withNewlines, at: .zero)
        },
        events: { event, _ in ([], [event]) },
        debugName: "Text"
    )
}
