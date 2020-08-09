////
///  Repeating.swift
//

public func Repeating<Msg>(_ view: View<Msg>) -> View<Msg> {
    return View(
        preferredSize: { _ in .zero },
        render: { viewport, buffer in
            guard !viewport.isEmpty else { return }

            let viewSize = view.preferredSize(viewport.size)
            guard viewSize.width > 0, viewSize.height > 0 else { return }
            var y = Int(viewport.visible.minY / viewSize.height)
            let x0 = Int(viewport.visible.minX / viewSize.width)
            var x: Int
            while y < viewport.visible.height {
                x = x0
                while x < viewport.visible.width {
                    let repeatingViewport = Viewport(
                        Rect(origin: Point(x: x, y: y), size: viewSize))
                    buffer.render(
                        key: "Repeating-\(x)-\(y)", view: view, viewport: repeatingViewport)
                    x += viewSize.width
                }
                y += viewSize.height
            }
        },
        events: { event, _ in ([], [event]) },
        debugName: "Repeating"
    )
}
