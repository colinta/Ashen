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
                    key: index, view: view, viewport: viewport.toViewport())
            }
        },
        events: { event, buffer in
            View.scan(views: views, event: event, buffer: buffer)
        },
        debugName: "ZStack"
    )
}
