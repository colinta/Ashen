////
///  OnClick.swift
//

public enum OnSingleClickOption {
    case highlight(Bool)
    case isEnabled(Bool)

    var toOnClickOption: OnClickOption {
        switch self {
        case let .highlight(highlight): return .highlight(highlight)
        case let .isEnabled(isEnabled): return .isEnabled(isEnabled)
        }
    }
}

public enum OnClickOption {
    case highlight(Bool)
    case isEnabled(Bool)
    case button(MouseEvent.Button)
}

private let NAME = "OnClick"

struct OnClickModel {
    let isHighlighted: Bool
}

public func OnLeftClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping @autoclosure SimpleEvent<Msg>,
    _ options: OnSingleClickOption...
) -> View<Msg> {
    OnButtonClick(.left, inside, msg, options, debugName: "OnLeftClick")
}

public func OnRightClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping @autoclosure SimpleEvent<Msg>,
    _ options: OnSingleClickOption...
) -> View<Msg> {
    OnButtonClick(.right, inside, msg, options, debugName: "OnRightClick")
}

public func OnMiddleClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping @autoclosure SimpleEvent<Msg>,
    _ options: OnSingleClickOption...
) -> View<Msg> {
    OnButtonClick(.middle, inside, msg, options, debugName: "OnLeftClick")
}

private func OnButtonClick<Msg>(
    _ button: MouseEvent.Button, _ inside: View<Msg>, _ msg: @escaping SimpleEvent<Msg>,
    _ options: [OnSingleClickOption], debugName: String
) -> View<Msg> {
    var highlight = true
    var isEnabled = true
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        case let .isEnabled(isEnabledOpt):
            isEnabled = isEnabledOpt
        }
    }

    let clickable = OnClick(inside, nil, options.map { $0.toOnClickOption } + [.button(button)])
    return View<Msg>(
        preferredSize: clickable.preferredSize,
        render: clickable.render,
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            guard isEnabled else { return (msgs, events) }
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    mouseEvent.button == button
                else {
                    return (msgs, [event])
                }
                guard
                    buffer.checkMouse(key: inside.viewKey ?? .name(NAME), mouse: mouseEvent)
                else {
                    let model: OnClickModel? = buffer.retrieve()
                    if model?.isHighlighted == true {
                        buffer.store(OnClickModel(isHighlighted: false))
                        return (msgs, [event, .redraw])
                    }
                    return (msgs, [event])
                }

                if mouseEvent.isReleased {
                    buffer.store(OnClickModel(isHighlighted: false))
                    return (msgs + [msg()], highlight ? [.redraw] : [])
                } else if mouseEvent.isDown && highlight {
                    buffer.store(OnClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [])
            }
        },
        debugName: debugName
    )
}

public func OnClick<Msg>(
    _ inside: View<Msg>, _ msg: @escaping (MouseEvent.Button) -> Msg, _ options: OnClickOption...
) -> View<Msg> {
    OnClick(inside, msg, options)
}

private func OnClick<Msg>(
    _ inside: View<Msg>, _ msg: ((MouseEvent.Button) -> Msg)?, _ options: [OnClickOption]
) -> View<Msg> {
    var highlight = true
    var isEnabled = true
    var buttons: [MouseEvent.Button] = []
    for opt in options {
        switch opt {
        case let .highlight(highlightOpt):
            highlight = highlightOpt
        case let .isEnabled(isEnabledOpt):
            isEnabled = isEnabledOpt
        case let .button(buttonOpt):
            buttons.append(buttonOpt)
        }
    }
    if buttons.isEmpty {
        buttons = [.left, .right, .middle]
    }

    return View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { viewport, buffer in
            guard isEnabled else {
                return inside.render(viewport, buffer)
            }

            let model: OnClickModel? = buffer.retrieve()
            let isHighlighted = model?.isHighlighted ?? false

            let mask: Buffer.Mask = buffer.mask
            inside.render(viewport, buffer)
            if highlight && isHighlighted {
                buffer.modifyCharacters(in: viewport.visible, mask: mask) { x, y, c in
                    c.styled(.reverse)
                }
            }
            // pay attention to the order - the first view to claim a mouse area
            // "wins" that area, and so usually you should claim the area
            // *after* the child view has had a chance.
            buffer.claimMouse(
                key: inside.viewKey ?? .name(NAME), rect: Rect(origin: .zero, size: viewport.size),
                mask: mask, buttons: buttons)
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            guard isEnabled else { return (msgs, events) }
            return View.scan(events: events) { event in
                guard
                    case let .mouse(mouseEvent) = event,
                    buffer.checkMouse(key: inside.viewKey ?? .name(NAME), mouse: mouseEvent)
                else { return (msgs, [event]) }

                if mouseEvent.isReleased {
                    buffer.store(OnClickModel(isHighlighted: false))
                    return (
                        msgs + (msg.map { [$0(mouseEvent.button)] } ?? []),
                        highlight ? [.redraw] : []
                    )
                } else if mouseEvent.isPressed && highlight {
                    buffer.store(OnClickModel(isHighlighted: true))
                    return (msgs, [.redraw])
                }
                return (msgs, [event])
            }
        },
        debugName: NAME
    )
}
