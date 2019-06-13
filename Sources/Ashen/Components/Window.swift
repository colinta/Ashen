////
///  Window.swift
//


class Window: ComponentLayout {

    convenience init(components: [Component]) {
        self.init()
        self.components = components
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: Int.max, height: Int.max)
    }

    static func render(views: [ComponentView], in buffer: Buffer, size screenSize: Size) {
        for view in views.reversed() {
            let viewSize = view.desiredSize().constrain(in: screenSize)
            let offset = view.location.origin(for: viewSize, in: screenSize)
            buffer.push(offset: offset, clip: viewSize) {
                view.render(in: buffer, size: viewSize)
            }
        }
    }
}
