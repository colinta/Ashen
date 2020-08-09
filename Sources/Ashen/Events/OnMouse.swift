////
///  OnMouse.swift
//

public enum OnMouseOption {
    case button(MouseEvent.Button)
}

private let KEY = "OnMouse"

public func OnMouse<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (MouseEvent) -> Msg, _ options: OnMouseOption...
) -> View<Msg> {
    var buttons: [MouseEvent.Button] = []
    for opt in options {
        switch opt {
        case let .button(buttonOpt):
            buttons.append(buttonOpt)
        }
    }
    if buttons.isEmpty {
        buttons = [.left, .right, .middle, .scroll]
    }

    return View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { viewport, buffer in
            let mask = buffer.mask
            inside.render(viewport, buffer)
            // pay attention to the order - the first view to claim a mouse area
            // "wins" that area, and so usually you should claim the area
            // *after* the child view has had a chance.
            buffer.claimMouse(
                key: KEY, rect: Rect(origin: .zero, size: viewport.size),
                mask: mask, buttons: buttons, view: inside)
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    buffer.checkMouse(key: KEY, mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }
                return (msgs + [msg(mouseEvent)], [])
            }
        },
        debugName: "OnMouse"
    )
}
