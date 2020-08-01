////
///  Mouse.swift
//

public enum MouseOptions {
}

public func OnMouse<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (MouseEvent) -> Msg, _ options: [MouseOptions] = []
) -> View<Msg> {
    View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { rect, buffer in
            inside.render(rect, buffer)
            // pay attention to the order - the first view to claim a mouse area
            // "wins" that area, and so usually you should claim the area
            // *after* the child view has had a chance.
            buffer.claimMouse(key: "OnMouse", rect: rect, view: inside)
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    buffer.checkMouse(key: "OnMouse", mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }
                return (msgs + [msg(mouseEvent)], [])
            }
        }
    )
}
