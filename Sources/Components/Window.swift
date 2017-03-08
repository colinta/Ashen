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

    static func render(components: [Component], in buffer: Buffer, size screenSize: Size) {
        for view in components {
            guard let view = view as? ComponentView else { continue }

            let viewSize = view.desiredSize().constrain(in: screenSize)
            let offset = view.location.origin(for: viewSize, in: screenSize)
            buffer.push(offset: offset) {
                view.render(in: buffer, size: viewSize)
            }
        }
    }
}
