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
    let background: AttrChar?
    let label: TextType?
    let scrollOffset: Point

    init(_ location: Location = .tl(.zero), _ size: Size = .zero, border: Border? = nil, background: TextType? = nil, label: TextType? = nil, components: [Component] = [], scrollOffset: Point = .zero) {
        self.size = size
        self.border = border
        self.background = background.flatMap { $0.chars.first }
        self.label = label
        self.scrollOffset = scrollOffset
        super.init()
        self.components = components
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(size)
    }

    override func render(in buffer: Buffer, size screenSize: Size) {
        if let label = label {
            var xOffset = 2
            for char in label.chars {
                if xOffset > screenSize.width - 4 { break }
                buffer.write(char, x: xOffset, y: 0)
                xOffset += 1
            }
        }

        // calculate size and offset for the inside of the box
        let innerSize: Size
        let borderOffset: Point
        if let border = border {
            let widthClip: Int, borderX: Int
            if border.leftSide == "" && border.rightSide == "" {
                widthClip = 0
                borderX = 0
            }
            else if border.leftSide == "" {
                widthClip = 1
                borderX = 0
            }
            else if border.rightSide == "" {
                widthClip = 1
                borderX = 1
            }
            else {
                widthClip = 2
                borderX = 1
            }

            let heightClip: Int, borderY: Int
            if border.topSide == "" && border.bottomSide == "" {
                heightClip = 0
                borderY = 0
            }
            else if border.topSide == "" {
                heightClip = 1
                borderY = 0
            }
            else if border.bottomSide == "" {
                heightClip = 1
                borderY = 1
            }
            else {
                heightClip = 2
                borderY = 1
            }

            borderOffset = Point(x: borderX, y: borderY)
            innerSize = Size(width: max(0, screenSize.width - widthClip), height: max(0, screenSize.height - heightClip))

            // draw the border
            let minX = 0, maxX = screenSize.width - 1
            let minY = 0, maxY = screenSize.height - 1
            switch (screenSize.width, screenSize.height) {
            case (1, 1):
                buffer.write(AttrChar(border.dot), x: minX, y: minY)
            case (_, 1):
                buffer.write(AttrChar(border.leftCap), x: minX, y: minY)
                buffer.write(AttrChar(border.rightCap), x: maxX, y: minY)
                if screenSize.width > 2 {
                    for x in 1 ..< maxX {
                        buffer.write(AttrChar(border.tbSide), x: x, y: minY)
                    }
                }
            case (1, _):
                buffer.write(AttrChar(border.topCap), x: minX, y: minY)
                buffer.write(AttrChar(border.bottomCap), x: minX, y: maxY)
                if screenSize.height > 2 {
                    for y in 1 ..< maxY {
                        buffer.write(AttrChar(border.lrSide), x: minX, y: y)
                    }
                }
            default:
                buffer.write(AttrChar(border.tlCorner), x: minX, y: minY)
                buffer.write(AttrChar(border.trCorner), x: maxX, y: minY)
                buffer.write(AttrChar(border.blCorner), x: minX, y: maxY)
                buffer.write(AttrChar(border.brCorner), x: maxX, y: maxY)
                if screenSize.width > 2 {
                    for x in 1 ..< maxX {
                        buffer.write(AttrChar(border.topSide), x: x, y: minY)
                        buffer.write(AttrChar(border.bottomSide), x: x, y: maxY)
                    }
                }
                if screenSize.height > 2 {
                    for y in 1 ..< maxY {
                        buffer.write(AttrChar(border.leftSide), x: minX, y: y)
                        buffer.write(AttrChar(border.rightSide), x: maxX, y: y)
                    }
                }
            }
        }
        else {
            borderOffset = .zero
            innerSize = screenSize
        }

        buffer.push(offset: borderOffset, clip: innerSize) {
            for view in views.reversed() {
                let viewSize = view.desiredSize().constrain(in: innerSize) + scrollOffset
                let offset = view.location.origin(for: viewSize, in: innerSize) - scrollOffset
                buffer.push(offset: offset, clip: viewSize) {
                    view.render(in: buffer, size: viewSize)
                }
            }

            if let background = background {
                for y in 0 ..< innerSize.height {
                    for x in 0 ..< innerSize.width {
                        buffer.write(background, x: x, y: y)
                    }
                }
            }
        }
    }
}
