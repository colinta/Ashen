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
                    key: index, view: view, viewport: viewport)
            }
        },
        events: { event, buffer in
            views.enumerated().reduce(([Msg](), [event])) { info, index_view in
                let (msgs, events) = info
                let (index, view) = index_view
                let (newMsgs, newEvents) = View.scan(events: events) { event in
                    return buffer.events(key: index, event: event, view: view)
                }
                return (msgs + newMsgs, newEvents)
            }
        },
        debugName: "Window"
    )
}
