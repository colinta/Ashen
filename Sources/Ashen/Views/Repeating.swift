////
///  Repeating.swift
//

public func Repeating<Msg>(_ view: View<Msg>) -> View<Msg> {
    return View(
        preferredSize: { $0 },
        render: { rect, buffer in
            let viewSize = view.preferredSize(rect.size)
            guard viewSize.width > 0, viewSize.height > 0 else { return }
            var x = 0
            var y = 0
            while y < rect.height {
                x = 0
                while x < rect.width {
                    buffer.render(
                        key: "Repeating-\(x)-\(y)", view: view, at: Point(x: x, y: y), clip: rect.size)
                    x += viewSize.width
                }
                y += viewSize.height
            }
        },
        events: { event, _ in ([], [event]) }
    )
}
