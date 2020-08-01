////
///  OnWindowResize.swift
//

public func OnWindowResize<Msg>(_ onResize: @escaping OnResizeHandler<Msg>) -> View<Msg> {
    View<Msg>(
        preferredSize: { _ in .zero },
        render: { _, _ in },
        events: { event, buffer in
            guard case let .window(width, height) = event else { return ([], [event]) }
            return ([onResize(Size(width: width, height: height))], [event])
        }
    )
}
