////
///  ZStack.swift
//

public func ZStack<Msg>(_ views: View<Msg>...) -> View<Msg> {
    ZStack(views)
}

public func ZStack<Msg>(_ views: [View<Msg>]) -> View<Msg> {
    View<Msg>(
        preferredSize: { size in
            views.reduce(Size.zero) { memo, view in
                let viewSize = view.preferredSize(size)
                return Size(
                    width: max(memo.width, viewSize.width),
                    height: max(memo.height, viewSize.height)
                )
            }
        },
        render: { viewport, buffer in
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
        debugName: "ZStack"
    )
}
