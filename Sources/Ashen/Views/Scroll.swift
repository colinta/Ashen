////
///  Scroll.swift
//

public enum ScrollOption {
    case offset(Point)
    public static func offset(x: Int) -> ScrollOption { .offset(Point(x: x, y: 0)) }
    public static func offset(y: Int) -> ScrollOption { .offset(Point(x: 0, y: y)) }
}

extension View {
    public func scrollable(offset: Point = .zero) -> View<Msg> {
        Scroll(self, .offset(offset))
    }
}

struct ScrollModel {
    let contentSize: Size
    let prevContentSize: Size?
    let mask: Rect
}

public func Scroll<Msg>(
    _ inside: View<Msg>, onResizeContent: ((Size, Rect) -> Msg)? = nil, _ options: ScrollOption...
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
                            contentSize: contentSize, prevContentSize: model.prevContentSize,
                            mask: viewport.mask))
                } else {
                    buffer.store(
                        ScrollModel(
                            contentSize: contentSize, prevContentSize: nil, mask: viewport.mask))
                }
            }

            let scrollViewport = Viewport(
                frame: Rect(origin: viewport.mask.origin - offset, size: contentSize),
                mask: viewport.mask
            )
            buffer.render(
                key: "Scroll", view: inside,
                viewport: scrollViewport)
        },
        events: { event, buffer in
            let (msgs, events) = buffer.events(key: "Scroll", event: event, view: inside)
            guard let onResizeContent = onResizeContent,
                let model: ScrollModel = buffer.retrieve(),
                model.contentSize != model.prevContentSize
            else {
                return (msgs, events)
            }
            return (msgs + [onResizeContent(model.contentSize, model.mask)], events)
        },
        debugName: "Scroll"
    )
}
