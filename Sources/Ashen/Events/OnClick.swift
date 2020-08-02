////
///  Click.swift
//

public enum ClickOptions {
    case highlight(Bool)
}

private let ON_CLICK_KEY = "OnClick"

struct ClickModel {
    let isHighlighted: Bool
}

public func OnLeftClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping @autoclosure () -> Msg, _ options: ClickOptions...
) -> View<Msg> {
    var highlight = false
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        }
    }

    let clickable = OnClick(inside, { _ in msg() }, options)
    return View<Msg>(
        preferredSize: clickable.preferredSize,
        render: clickable.render,
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    mouseEvent.button == .left,
                    buffer.checkMouse(key: ON_CLICK_KEY, mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }

                if mouseEvent.isReleased {
                    buffer.store(ClickModel(isHighlighted: false))
                    return (msgs + [msg()], highlight ? [.redraw] : [])
                } else if mouseEvent.isPressed && highlight {
                    buffer.store(ClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [])
            }
        }
    )
}

public func OnRightClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping @autoclosure () -> Msg, _ options: ClickOptions...
) -> View<Msg> {
    var highlight = false
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        }
    }

    let clickable = OnClick(inside, { _ in msg() }, options)
    return View<Msg>(
        preferredSize: clickable.preferredSize,
        render: clickable.render,
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    mouseEvent.button == .right,
                    buffer.checkMouse(key: ON_CLICK_KEY, mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }

                if mouseEvent.isReleased {
                    buffer.store(ClickModel(isHighlighted: false))
                    return (msgs + [msg()], highlight ? [.redraw] : [])
                } else if mouseEvent.isPressed && highlight {
                    buffer.store(ClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [])
            }
        }
    )
}

public func OnClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (MouseEvent) -> Msg, _ options: ClickOptions...
) -> View<Msg> {
    OnClick(inside, msg, options)
}

private func OnClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (MouseEvent) -> Msg, _ options: [ClickOptions]
) -> View<Msg> {
    var highlight = false
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        }
    }

    return View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { rect, buffer in
            inside.render(rect, buffer)
            let model: ClickModel? = buffer.retrieve()
            let isHighlighted = model?.isHighlighted ?? false
            if highlight && isHighlighted {
                buffer.modifyCharacters(in: rect) { x, y, c in
                    c.styled(.reverse)
                }
            }
            // pay attention to the order - the first view to claim a mouse area
            // "wins" that area, and so usually you should claim the area
            // *after* the child view has had a chance.
            buffer.claimMouse(key: ON_CLICK_KEY, rect: rect, view: inside)
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    buffer.checkMouse(key: ON_CLICK_KEY, mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }

                if mouseEvent.isReleased {
                    buffer.store(ClickModel(isHighlighted: false))
                    return (msgs + [msg(mouseEvent)], highlight ? [.redraw] : [])
                } else if mouseEvent.isPressed && highlight {
                    buffer.store(ClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [event])
            }
        }
    )
}
