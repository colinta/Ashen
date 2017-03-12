////
///  FlowLayout.swift
//


/// Usage:
///     FlowLayout(location, size, orientation, components: [ComponentView])
///     FlowLayout(location, size, orientation, direction: .ltr, components: [ComponentView])
class FlowLayout: ComponentLayout {
    enum Orientation {
        case vertical
        case horizontal
    }

    enum Direction {
        case ltr
        case rtl
    }

    let orientation: Orientation
    let direction: Direction
    let size: Size

    static func horizontal(_ size: Size, direction: Direction = .ltr, components: [Component]) -> FlowLayout {
        return FlowLayout(.tl(.zero), size, orientation: .horizontal, direction: direction, components: components)
    }

    static func vertical(_ size: Size, direction: Direction = .ltr, components: [Component]) -> FlowLayout {
        return FlowLayout(.tl(.zero), size, orientation: .vertical, direction: direction, components: components)
    }

    convenience init(_ size: Size, orientation: Orientation, direction: Direction = .ltr, components: [Component]) {
        self.init(.tl(.zero), size, orientation: orientation, direction: direction, components: components)
    }

    init(_ location: Location, _ size: Size, orientation: Orientation, direction: Direction = .ltr, components: [Component]) {
        self.size = size
        self.orientation = orientation
        self.direction = direction
        super.init()
        self.components = components
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(size)
    }

    override func render(in buffer: Buffer, size screenSize: Size) {
        switch orientation {
        case .horizontal:
            horizontalLayout(in: buffer, size: screenSize)
        case .vertical:
            verticalLayout(in: buffer, size: screenSize)
        }
    }

    func horizontalLayout(in buffer: Buffer, size screenSize: Size) {
        var viewX = direction == .ltr ? 0 : screenSize.width
        var viewY = 0
        var rowHeight = 0
        for view in views {
            let viewSize = view.desiredSize().constrain(in: screenSize)

            rowHeight = max(rowHeight, viewSize.height)

            let offset: Point
            if direction == .ltr {
                if viewX + viewSize.width > screenSize.width {
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
                    viewX = screenSize.width - viewSize.width
                }
                offset = Point(x: viewX, y: viewY)
            }

            buffer.push(offset: offset, clip: viewSize) {
                view.render(in: buffer, size: viewSize)
            }
        }
    }

    func verticalLayout(in buffer: Buffer, size screenSize: Size) {
        var viewX = direction == .ltr ? 0 : screenSize.width
        var viewY = 0
        var colWidth = 0
        for view in views {
            let viewSize = view.desiredSize().constrain(in: screenSize)

            colWidth = max(colWidth, viewSize.width)

            if viewY + viewSize.height > screenSize.height {
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
                view.render(in: buffer, size: viewSize)
            }
        }
    }

}
