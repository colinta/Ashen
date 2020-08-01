////
///  Text.swift
//

public func Text<Msg>(_ text: Attributed) -> View<Msg> {
    View(
        preferredSize: { _ in Size(width: text.maxWidth, height: text.countLines) },
        render: { _, buffer in
            buffer.write(text, at: .zero)
        },
        events: { event, _ in ([], [event]) }
    )
}
