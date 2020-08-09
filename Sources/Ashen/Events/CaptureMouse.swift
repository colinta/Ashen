////
///  ClaimMouse.swift
//

private let ON_MOUSE_KEY = "ClaimMouse"

public func ClaimMouse<Msg>(
    _ inside: View<Msg>, _ options: OnMouseOption...
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
                key: ON_MOUSE_KEY, rect: Rect(origin: .zero, size: viewport.size),
                mask: mask, buttons: buttons, view: inside)
        },
        events: { event, buffer in
            inside.events(event, buffer)
        },
        debugName: "ClaimMouse"
    )
}
