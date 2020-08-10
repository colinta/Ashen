////
///  Scroll.swift
//

public enum ScrollOption {
    case offset(Point)
    public static func offset(x: Int) -> ScrollOption { .offset(Point(x: x, y: 0)) }
    public static func offset(y: Int) -> ScrollOption { .offset(Point(x: 0, y: y)) }
}

extension View {
    public func scrollable(offset: Point) -> View<Msg> {
        Scroll(self, .offset(offset))
    }
}

struct ScrollModel {
    let scrollableViewport: LocalViewport
    let prevViewport: LocalViewport?
}

public func Scroll<Msg>(
    _ inside: View<Msg>, onResizeContent: ((LocalViewport) -> Msg)? = nil,
    _ options: ScrollOption...
) -> View<Msg> {
    var offset: Point = .zero
    for opt in options {
        switch opt {
        case let .offset(offsetOpt):
            offset = offsetOpt
        }
    }

    return View<Msg>(
        preferredSize: { $0 },
        render: { viewport, buffer in
            guard !viewport.isEmpty else {
                buffer.render(key: "Box", view: inside, viewport: .zero)
                return
            }

            let contentSize = inside.preferredSize(viewport.size)
            if onResizeContent != nil {
                if let model: ScrollModel = buffer.retrieve() {
                    buffer.store(
                        ScrollModel(
                            scrollableViewport: LocalViewport(
                                size: contentSize, visible: viewport.visible),
                            prevViewport: model.scrollableViewport))
                } else {
                    buffer.store(
                        ScrollModel(
                            scrollableViewport: LocalViewport(
                                size: contentSize, visible: viewport.visible), prevViewport: nil))
                }
            }

            let scrollViewport = Viewport(
                frame: Rect(origin: viewport.visible.origin - offset, size: contentSize),
                visible: viewport.visible
            )
            buffer.render(
                key: "Scroll", view: inside,
                viewport: scrollViewport)
        },
        events: { event, buffer in
            let (msgs, events) = buffer.events(key: "Scroll", event: event, view: inside)
            guard let onResizeContent = onResizeContent,
                let model: ScrollModel = buffer.retrieve(),
                model.scrollableViewport != model.prevViewport
            else {
                return (msgs, events)
            }
            return (msgs + [onResizeContent(model.scrollableViewport)], events)
        },
        debugName: "Scroll"
    )
}
