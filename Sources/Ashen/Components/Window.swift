////
///  Window.swift
//


public class Window: ComponentLayout {

    public convenience init(components: [Component]) {
        self.init()
        self.components = components
    }

    override public func desiredSize() -> DesiredSize {
        return DesiredSize(width: .max, height: .max)
    }

    static func render(
        views: [Component],
        to buffer: Buffer,
        in rect: Rect,
        contentSize: Size? = nil
    ) {
        let actualContentSize = contentSize ?? rect.size + rect.origin
        let localRect = Rect(size: rect.size)

        for view in views.reversed() {
            if let view = view as? ComponentView {
                let viewSize = view.desiredSize().constrain(in: actualContentSize)
                let viewOffset = view.location.origin(for: viewSize, in: actualContentSize)
                    - rect.origin

                let innerRect = localRect.intersection(Rect(origin: viewOffset, size: viewSize))
                    .map({ $0 - viewOffset })
                if let innerRect = innerRect {
                    buffer.push(offset: viewOffset, clip: viewSize) {
                        view.render(to: buffer, in: innerRect)
                    }
                }
            }
            else {
                view.render(to: buffer, in: localRect)
            }
        }
    }
}
