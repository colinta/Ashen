////
///  OnMouseWheel.swift
//

private let KEY = "OnMouseWheel"

public func OnMouseWheel<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (Int) -> Msg
) -> View<Msg> {
    View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { viewport, buffer in
            let mask = buffer.mask
            inside.render(viewport, buffer)
            buffer.claimMouse(
                key: KEY, rect: Rect(origin: .zero, size: viewport.size),
                mask: mask, buttons: [.scroll], view: inside)
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    case let .scroll(direction) = mouseEvent.event,
                    buffer.checkMouse(key: KEY, mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }
                return (msgs + [msg(direction == .up ? -1 : 1)], [])
            }
        },
        debugName: "OnMouse"
    )
}
