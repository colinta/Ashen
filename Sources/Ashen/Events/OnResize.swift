////
///  OnResize.swift
//

public typealias OnResizeHandler<Msg> = (Size) -> Msg

struct OnResizeModel {
    let size: Size
    let prevSize: Size?
}

public func OnResize<Msg>(_ inside: View<Msg>, _ onResize: @escaping OnResizeHandler<Msg>) -> View<
    Msg
> {
    View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { rect, buffer in
            inside.render(rect, buffer)

            if let model: OnResizeModel = buffer.retrieve() {
                buffer.store(OnResizeModel(size: rect.size, prevSize: model.size))
            } else {
                buffer.store(OnResizeModel(size: rect.size, prevSize: nil))
            }
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            return View.scan(events: events) { event in
                guard let model: OnResizeModel = buffer.retrieve(),
                    model.size != model.prevSize
                else { return (msgs, [event]) }
                return (msgs + [onResize(model.size)], [event])
            }
        }
    )
}
