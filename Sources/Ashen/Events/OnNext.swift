////
///  OnNext.swift
//

public func OnNext<Msg>(_ onNext: @escaping SimpleHandler<Msg>) -> View<Msg> {
    View<Msg>(
        preferredSize: { _ in .zero },
        render: { _, _ in },
        events: { event, buffer in
            guard case .tick = event else { return ([], [event]) }
            return ([onNext()], [event])
        },
        debugName: "OnNext"
    )
}
