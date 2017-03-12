////
///  Box.swift
//

class Box: ComponentLayout {
    struct Border {
        let dot: String
        let topCap: String
        let bottomCap: String
        let leftCap: String
        let rightCap: String
        let tlCorner: String
        let trCorner: String
        let blCorner: String
        let brCorner: String
        let topSide: String
        let bottomSide: String
        let tbSide: String
        let leftSide: String
        let rightSide: String
        let lrSide: String

        init(
            dot: String? = nil, topCap: String? = nil, bottomCap: String? = nil, leftCap: String? = nil, rightCap: String? = nil,
            tlCorner: String, trCorner: String, blCorner: String, brCorner: String,
            tbSide: String, topSide: String? = nil, bottomSide: String? = nil,
            lrSide: String, leftSide: String? = nil, rightSide: String? = nil
            )
        {
            self.tlCorner = tlCorner
            self.trCorner = trCorner
            self.blCorner = blCorner
            self.brCorner = brCorner
            self.tbSide = tbSide
            self.lrSide = lrSide

            self.dot = dot ?? tlCorner
            self.topCap = topCap ?? tlCorner
            self.bottomCap = bottomCap ?? blCorner
            self.leftCap = leftCap ?? tlCorner
            self.rightCap = rightCap ?? trCorner
            self.topSide = topSide ?? tbSide
            self.bottomSide = bottomSide ?? tbSide
            self.leftSide = leftSide ?? lrSide
            self.rightSide = rightSide ?? lrSide

        }

        static let lame = Border(
            tlCorner: "+", trCorner: "+", blCorner: "+", brCorner: "+",
            tbSide: "-",
            lrSide: "|"
            )
        static let single = Border(
            dot: "◻︎", topCap: "┬", bottomCap: "┴", leftCap: "├", rightCap: "┤",
            tlCorner: "┌", trCorner: "┐", blCorner: "└", brCorner: "┘",
            tbSide: "─", lrSide: "│"
            )
        static let double = Border(
            dot: "◻︎", topCap: "╥", bottomCap: "╨", leftCap: "╟", rightCap: "╢",
            tlCorner: "╔", trCorner: "╗", blCorner: "╚", brCorner: "╝",
            tbSide: "═", lrSide: "║"
            )
        static let rounded = Border(
            dot: "▢", topCap: "╷", bottomCap: "╵", leftCap: "╶", rightCap: "╴",
            tlCorner: "╭", trCorner: "╮", blCorner: "╰", brCorner: "╯",
            tbSide: "─", lrSide: "│"
            )
        static let bold = Border(
            dot: "◼︎", topCap: "┳", bottomCap: "┻", leftCap: "┣", rightCap: "┫",
            tlCorner: "┏", trCorner: "┓", blCorner: "┗", brCorner: "┛",
            tbSide: "━", lrSide: "┃"
            )
        // static let double = Border(
        // static let mixed = Border(
    }

    let size: Size
    let border: Border?
    let background: TextType?

    init(_ location: Location, _ size: Size, border: Border? = nil, background: TextType? = nil, components: [Component] = []) {
        self.size = size
        self.border = border
        self.background = background
        super.init()
        self.components = components
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(size)
    }

    override func render(in buffer: Buffer, size screenSize: Size) {
        let size: Size
        let borderOffset: Point
        if border == nil {
            borderOffset = .zero
            size = screenSize
        }
        else {
            borderOffset = Point(x: 1, y: 1)
            size = Size(width: max(0, screenSize.width - 2), height: max(0, screenSize.height - 2))
        }

        buffer.push(offset: borderOffset, clip: size) {
            if let background = background {
                for y in 0 ..< size.height {
                    for x in 0 ..< size.width {
                        buffer.write(background, x: x, y: y)
                    }
                }
            }

            for view in views.reversed() {
                let viewSize = view.desiredSize().constrain(in: size)
                let offset = view.location.origin(for: viewSize, in: size)
                buffer.push(offset: offset, clip: viewSize) {
                    view.render(in: buffer, size: viewSize)
                }
            }
        }

        if let border = border {
            let minX = 0, maxX = screenSize.width - 1
            let minY = 0, maxY = screenSize.height - 1
            switch (screenSize.width, screenSize.height) {
            case (1, 1):
                buffer.write(border.dot, x: minX, y: minY)
            case (_, 1):
                buffer.write(border.leftCap, x: minX, y: minY)
                buffer.write(border.rightCap, x: maxX, y: minY)
                if screenSize.width > 2 {
                    for x in 1 ..< maxX {
                        buffer.write(border.tbSide, x: x, y: minY)
                    }
                }
            case (1, _):
                buffer.write(border.topCap, x: minX, y: minY)
                buffer.write(border.bottomCap, x: minX, y: maxY)
                if screenSize.height > 2 {
                    for y in 1 ..< maxY {
                        buffer.write(border.lrSide, x: minX, y: y)
                    }
                }
            default:
                buffer.write(border.tlCorner, x: minX, y: minY)
                buffer.write(border.trCorner, x: maxX, y: minY)
                buffer.write(border.blCorner, x: minX, y: maxY)
                buffer.write(border.brCorner, x: maxX, y: maxY)
                if screenSize.width > 2 {
                    for x in 1 ..< maxX {
                        buffer.write(border.topSide, x: x, y: minY)
                        buffer.write(border.bottomSide, x: x, y: maxY)
                    }
                }
                if screenSize.height > 2 {
                    for y in 1 ..< maxY {
                        buffer.write(border.leftSide, x: minX, y: y)
                        buffer.write(border.rightSide, x: maxX, y: y)
                    }
                }
            }
        }
    }
}
