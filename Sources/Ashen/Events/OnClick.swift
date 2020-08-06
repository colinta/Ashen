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
    OnLeftOrRightClick(.left, inside, msg, options).debugName("OnLeftClick")
}

public func OnRightClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping @autoclosure () -> Msg, _ options: ClickOptions...
) -> View<Msg> {
    OnLeftOrRightClick(.right, inside, msg, options).debugName("OnRightClick")
}

private func OnLeftOrRightClick<Msg>(
    _ button: MouseEvent.Button, _ inside: View<Msg>, _ msg: @escaping () -> Msg,
    _ options: [ClickOptions]
) -> View<Msg> {
    var highlight = true
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        }
    }

    let clickable = OnClick(inside, nil, options)
    return View<Msg>(
        preferredSize: clickable.preferredSize,
        render: clickable.render,
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    mouseEvent.button == button
                else {
                    return (msgs, [event])
                }
                guard
                    buffer.checkMouse(key: ON_CLICK_KEY, mouse: mouseEvent, view: inside)
                else {
                    let model: ClickModel? = buffer.retrieve()
                    if model?.isHighlighted == true {
                        buffer.store(ClickModel(isHighlighted: false))
                        return (msgs, [event, .redraw])
                    }
                    return (msgs, [event])
                }

                if mouseEvent.isReleased {
                    buffer.store(ClickModel(isHighlighted: false))
                    return (msgs + [msg()], highlight ? [.redraw] : [])
                } else if mouseEvent.isDown && highlight {
                    buffer.store(ClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [])
            }
        },
        debugName: ""
    )
}

public func OnClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (MouseEvent.Button) -> Msg, _ options: ClickOptions...
) -> View<Msg> {
    OnClick(inside, msg, options)
}

private func OnClick<Msg>(
    _ inside: View<Msg>, _ msg: ((MouseEvent.Button) -> Msg)?, _ options: [ClickOptions]
) -> View<Msg> {
    var highlight = true
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        }
    }

    return View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { viewport, buffer in
            let model: ClickModel? = buffer.retrieve()
            let isHighlighted = model?.isHighlighted ?? false

            let mask: Buffer.Mask? = highlight && isHighlighted ? buffer.mask : nil
            inside.render(viewport, buffer)
            if highlight && isHighlighted {
                buffer.modifyCharacters(in: viewport.mask, mask: mask) { x, y, c in
                    c.styled(.reverse)
                }
            }
            // pay attention to the order - the first view to claim a mouse area
            // "wins" that area, and so usually you should claim the area
            // *after* the child view has had a chance.
            buffer.claimMouse(
                key: ON_CLICK_KEY, rect: Rect(origin: .zero, size: viewport.frame.size),
                view: inside)
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    buffer.checkMouse(key: ON_CLICK_KEY, mouse: mouseEvent, view: inside)
                else { return (msgs, [event]) }

                if mouseEvent.isReleased, let button = mouseEvent.button {
                    buffer.store(ClickModel(isHighlighted: false))
                    return (msgs + (msg.map { [$0(button)] } ?? []), highlight ? [.redraw] : [])
                } else if mouseEvent.isPressed && highlight {
                    buffer.store(ClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [event])
            }
        },
        debugName: "OnClick"
    )
}
