////
///  Space.swift
//

public func Space<Msg>() -> View<Msg> {
    View(
        preferredSize: { _ in .zero },
        render: { _, _ in },
        events: { event, _ in ([], [event]) }
    )
}
