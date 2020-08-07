////
///  OnResize.swift
//

public typealias OnResizeEvent<Msg> = (Size) -> Msg

struct OnResizeModel {
    let size: Size
    let prevSize: Size?
}

public func OnResize<Msg>(_ inside: View<Msg>, _ onResize: @escaping OnResizeEvent<Msg>) -> View<
    Msg
> {
    View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { viewport, buffer in
            inside.render(viewport, buffer)

            if let model: OnResizeModel = buffer.retrieve() {
                buffer.store(OnResizeModel(size: viewport.size, prevSize: model.size))
            } else {
                buffer.store(OnResizeModel(size: viewport.size, prevSize: nil))
            }
        },
        events: { event, buffer in
            let (msgs, events) = inside.events(event, buffer)
            guard let model: OnResizeModel = buffer.retrieve(),
                model.size != model.prevSize
            else { return (msgs, events) }
            return (msgs + [onResize(model.size)], events)
        },
        debugName: "OnResize"
    )
}
