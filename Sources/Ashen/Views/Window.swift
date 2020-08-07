////
///  Window.swift
//

public func Window<Msg>(_ views: [View<Msg>]) -> View<Msg> {
    View<Msg>(
        preferredSize: { $0 },
        render: { viewport, buffer in
            guard !viewport.isEmpty else {
                for (index, view) in views.enumerated() {
                    buffer.render(key: index, view: view, viewport: .zero)
                }
                return
            }

            for (index, view) in views.enumerated() {
                buffer.render(
                    key: index, view: view, viewport: viewport.toViewport())
            }
        },
        events: { event, buffer in
            View.scan(views: views, event: event, buffer: buffer)
        },
        debugName: "Window"
    )
}
