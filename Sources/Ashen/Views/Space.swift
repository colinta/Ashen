////
///  Space.swift
//

public func Space<Msg>(width: Int = 0, height: Int = 0) -> View<Msg> {
    View(
        preferredSize: { _ in Size(width: width, height: height) },
        render: { _, _ in },
        events: { event, _ in ([], [event]) },
        debugName: "Space\(_debugDesc(width, height))"
    )
}

private func _debugDesc(_ width: Int, _ height: Int) -> String {
    if width > 0 && height > 0 {
        return "(width: \(width), height: \(height))"
    } else if width > 0 {
        return "(width: \(width))"
    } else if height > 0 {
        return "(height: \(height))"
    } else {
        return ""
    }
}
