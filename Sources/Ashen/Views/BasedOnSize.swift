////
///  BasedOnSize.swift
//

public func BasedOnSize<Msg>(_ choose: @escaping (Size) -> View<Msg>) -> View<Msg> {
    var currentView: View<Msg>?
    return View(
        preferredSize: { size in
            let view = choose(size)
            return view.preferredSize(size)
        },
        render: { viewport, buffer in
            let view = choose(viewport.size)
            currentView = view
            view.render(viewport, buffer)
        },
        events: { event, buffer in
            guard let currentView = currentView else { return ([], [event]) }
            return currentView.events(event, buffer)
        },
        debugName: "BasedOnSize"
    )
}
