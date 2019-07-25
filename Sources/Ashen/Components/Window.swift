////
///  Window.swift
//


public class Window: ComponentLayout {

    public convenience init(components: [Component]) {
        self.init()
        self.components = components
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: Int.max, height: Int.max)
    }

    static func render(views: [ComponentView], to buffer: Buffer, in rect: Rect) {
        for view in views.reversed() {
            let viewSize = view.desiredSize().constrain(in: rect.size)
            let offset = view.location.origin(for: viewSize, in: rect.size) - rect.origin
            buffer.push(offset: offset, clip: viewSize) {
                view.render(to: buffer, in: Rect(size: viewSize))
            }
        }
    }
}
