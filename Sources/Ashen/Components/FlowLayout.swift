////
///  FlowLayout.swift
//


/// Usage:
///     FlowLayout(location, size, orientation, components: [ComponentView])
///     FlowLayout(location, size, orientation, direction: .ltr, components: [ComponentView])
public class FlowLayout: ComponentLayout {
    public enum Orientation {
        case vertical
        case horizontal
    }

    public enum Direction {
        case ltr
        case rtl
    }

    let orientation: Orientation
    let direction: Direction
    let size: DesiredSize

    public static func horizontal(size: DesiredSize = DesiredSize(), direction: Direction = .ltr, components: [Component]) -> FlowLayout {
        return FlowLayout(at: .tl(.zero), size: size, orientation: .horizontal, direction: direction, components: components)
    }

    public static func vertical(size: DesiredSize = DesiredSize(), direction: Direction = .ltr, components: [Component]) -> FlowLayout {
        return FlowLayout(at: .tl(.zero), size: size, orientation: .vertical, direction: direction, components: components)
    }

    public convenience init(size: DesiredSize = DesiredSize(), orientation: Orientation, direction: Direction = .ltr, components: [Component]) {
        self.init(at: .tl(.zero), size: size, orientation: orientation, direction: direction, components: components)
    }

    public init(at location: Location = .tl(.zero), size: DesiredSize = DesiredSize(), orientation: Orientation = .horizontal, direction: Direction = .ltr, components: [Component]) {
        self.size = size
        self.orientation = orientation
        self.direction = direction
        super.init()
        self.components = components
        self.location = location
    }

    override public func desiredSize() -> DesiredSize {
        return size
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        switch orientation {
        case .horizontal:
            horizontalLayout(to: buffer, in: Rect(size: rect.size))
        case .vertical:
            verticalLayout(to: buffer, in: Rect(size: rect.size))
        }
    }

    private func horizontalLayout(to buffer: Buffer, in rect: Rect) {
        var viewX = direction == .ltr ? 0 : rect.size.width
        var viewY = 0
        var rowHeight = 0
        for component in components {
            guard let view = component as? ComponentView else {
                component.render(to: buffer, in: rect)
                continue
            }
            let viewSize = view.desiredSize().constrain(in: rect.size)

            rowHeight = max(rowHeight, viewSize.height)

            let offset: Point
            if direction == .ltr {
                if viewX + viewSize.width > rect.size.width {
                    viewY += rowHeight
                    rowHeight = viewSize.height
                    viewX = 0
                }
                offset = Point(x: viewX, y: viewY)
                viewX += viewSize.width
            }
            else {
                viewX -= viewSize.width
                if viewX < 0 {
                    viewY += rowHeight
                    rowHeight = viewSize.height
                    viewX = rect.size.width - viewSize.width
                }
                offset = Point(x: viewX, y: viewY)
            }

            buffer.push(offset: offset, clip: viewSize) {
                view.render(to: buffer, in: Rect(size: viewSize))
            }
        }
    }

    private func verticalLayout(to buffer: Buffer, in rect: Rect) {
        var viewX = direction == .ltr ? 0 : rect.size.width
        var viewY = 0
        var colWidth = 0
        for component in components {
            guard let view = component as? ComponentView else {
                component.render(to: buffer, in: rect)
                continue
            }
            let viewSize = view.desiredSize().constrain(in: rect.size)

            colWidth = max(colWidth, viewSize.width)

            if viewY + viewSize.height > rect.size.height {
                if direction == .ltr {
                    viewX += colWidth
                }
                else {
                    viewX -= colWidth
                }
                colWidth = 0
                viewY = 0
            }

            let offset: Point
            if direction == .ltr {
                offset = Point(x: viewX, y: viewY)
            }
            else {
                offset = Point(x: viewX - viewSize.width, y: viewY)
            }
            viewY += viewSize.height

            buffer.push(offset: offset, clip: viewSize) {
                view.render(to: buffer, in: Rect(size: viewSize))
            }
        }
    }

}
