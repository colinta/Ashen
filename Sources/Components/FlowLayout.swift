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

    override func chars(in screenSize: Size) -> Screen.Chars {
        switch orientation {
        case .horizontal:
            return horizontalLayout(in: screenSize)
        case .vertical:
            return verticalLayout(in: screenSize)
        }
    }

    func horizontalLayout(in screenSize: Size) -> Screen.Chars {
        var viewX = direction == .ltr ? 0 : screenSize.width
        var viewY = 0
        var rowHeight = 0
        var chars: Screen.Chars = [:]
        for view in components {
            guard let view = view as? ComponentView else { continue }

            let viewSize = view.desiredSize().constrain(in: screenSize)
            let viewChars = view.chars(in: viewSize)

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

            for (y, row) in viewChars {
                let currentY = offset.y + y
                if currentY < 0 || currentY >= screenSize.height { continue }

                var newRow = chars[currentY] ?? [:]
                for (x, c) in row {
                    let currentX = offset.x + x
                    if currentX < 0 || currentX >= screenSize.width { continue }

                    newRow[currentX] = c
                }
                chars[currentY] = newRow
            }
        }
        return chars
    }

    func verticalLayout(in screenSize: Size) -> Screen.Chars {
        var viewX = direction == .ltr ? 0 : screenSize.width
        var viewY = 0
        var colWidth = 0
        var chars: Screen.Chars = [:]
        for view in components {
            guard let view = view as? ComponentView else { continue }

            let viewSize = view.desiredSize().constrain(in: screenSize)
            let viewChars = view.chars(in: viewSize)

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

            for (y, row) in viewChars {
                let currentY = offset.y + y
                if currentY < 0 || currentY >= screenSize.height { continue }

                var newRow = chars[currentY] ?? [:]
                for (x, c) in row {
                    let currentX = offset.x + x
                    if currentX < 0 || currentX >= screenSize.width { continue }

                    newRow[currentX] = c
                }
                chars[currentY] = newRow
            }
        }
        return chars
    }

}
