////
///  Scroll.swift
//

public enum ScrollOptions {
    case offset(Point)
    public static func offset(x: Int) -> ScrollOptions { .offset(Point(x: x, y: 0)) }
    public static func offset(y: Int) -> ScrollOptions { .offset(Point(x: 0, y: y)) }
}

extension View {
    public func scrollable(offset: Point = .zero) -> View<Msg> {
        Scroll(self, .offset(offset))
    }
}

public func Scroll<Msg>(_ inside: View<Msg>, _ options: ScrollOptions...) -> View<Msg> {
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

            let innerPreferredSize = inside.preferredSize(viewport.size)

            let scrollViewport = Viewport(
                frame: Rect(origin: viewport.mask.origin - offset, size: innerPreferredSize),
                mask: viewport.mask
            )
            buffer.render(
                key: "Scroll", view: inside,
                viewport: scrollViewport)
        },
        events: { event, buffer in
            buffer.events(key: "Scroll", event: event, view: inside)
        },
        debugName: "Scroll"
    )
}
