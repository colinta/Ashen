////
///  Box.swift
//

public enum BoxOptions {
    case border(BoxBorder)
    case title(Attributed)
    case alignment(Alignment)
}

extension View {
    public func border(_ border: BoxBorder, _ options: BoxOptions...) -> View<Msg> {
        Box(self, [.border(border)] + options)
    }
}

public func Box<Msg>(_ inside: View<Msg>, _ options: BoxOptions...) -> View<Msg> {
    Box(inside, options)
}

public func Box<Msg>(_ inside: View<Msg>, _ options: [BoxOptions] = []) -> View<Msg> {
    var border: BoxBorder = .single
    var title: Attributed?
    var frameOptions: [FrameOptions] = []
    for opt in options {
        switch opt {
        case let .border(borderOpt):
            border = borderOpt
        case let .title(titleOpt):
            title = titleOpt
        case let .alignment(alignmentOpt):
            frameOptions.append(.alignment(alignmentOpt))
        }
    }

    let framedInside = Frame(inside, frameOptions)

    let maxSidesWidth =
        max(border.tlCorner.maxWidth, border.leftSide.maxWidth, border.blCorner.maxWidth)
        + max(border.trCorner.maxWidth, border.rightSide.maxWidth, border.brCorner.maxWidth)
    let maxTopsHeight =
        max(border.tlCorner.countLines, border.topSide.countLines, border.trCorner.countLines)
        + max(border.blCorner.countLines, border.bottomSide.countLines, border.brCorner.countLines)
    let minSidesWidth =
        min(border.tlCorner.maxWidth, border.leftSide.maxWidth, border.blCorner.maxWidth)
        + min(border.trCorner.maxWidth, border.rightSide.maxWidth, border.brCorner.maxWidth)
    let minTopsHeight =
        min(border.tlCorner.countLines, border.topSide.countLines, border.trCorner.countLines)
        + min(border.bottomSide.countLines, border.blCorner.countLines, border.brCorner.countLines)

    return View<Msg>(
        preferredSize: { size in
            let innerSize = size.shrink(width: minSidesWidth, height: minTopsHeight)
            return framedInside.preferredSize(innerSize).grow(
                width: minSidesWidth,
                height: minTopsHeight
            )
        },
        render: { viewport, buffer in
            guard !viewport.isEmpty else {
                buffer.render(key: "Box", view: framedInside, viewport: .zero)
                return
            }

            let innerBorderSize = viewport.frame.size.shrink(
                width: minSidesWidth,
                height: minTopsHeight
            )
            let innerVisibleSize = viewport.frame.size.shrink(
                width: maxSidesWidth,
                height: maxTopsHeight
            )

            buffer.write(border.tlCorner, at: .zero)
            buffer.write(
                border.trCorner,
                at: Point(x: viewport.frame.size.width - border.trCorner.maxWidth, y: 0)
            )
            buffer.write(
                border.blCorner,
                at: Point(x: 0, y: viewport.frame.size.height - border.blCorner.countLines))
            buffer.write(
                border.brCorner,
                at: Point(
                    x: viewport.frame.size.width - border.trCorner.maxWidth,
                    y: viewport.frame.size.height - border.brCorner.countLines))

            if let title = title {
                let titleWidth = title.maxWidth
                let titleLabelWidth =
                    titleWidth + border.rightCap.maxWidth + border.leftCap.maxWidth + 2
                let titleY = (border.topSide.countLines) / 2
                let leftWidth = max(0, Int((innerBorderSize.width - titleLabelWidth) / 2))
                let rightWidth = max(0, innerBorderSize.width - leftWidth - titleLabelWidth)
                let titleTextWidth =
                    innerBorderSize.width - leftWidth - rightWidth - border.rightCap.maxWidth
                    - border.leftSide.maxWidth - 2
                buffer.write(
                    border.rightCap, at: Point(x: border.tlCorner.maxWidth + leftWidth, y: 0))
                buffer.write(
                    border.leftCap,
                    at: Point(
                        x: viewport.frame.size.width - border.trCorner.maxWidth - rightWidth
                            - border.leftCap.maxWidth, y: 0))
                buffer.write(
                    " ",
                    at: Point(
                        x: border.tlCorner.maxWidth + leftWidth + border.rightCap.maxWidth,
                        y: titleY), attributes: [.underline])
                buffer.write(
                    titleTextWidth < titleWidth ? "…" : " ",
                    at: Point(
                        x: viewport.frame.size.width - rightWidth - border.leftCap.maxWidth
                            - border.trCorner.maxWidth - 1, y: titleY), attributes: [.underline])

                var x = 0
                while x < innerBorderSize.width {
                    if x < leftWidth {
                        buffer.write(
                            border.topSide, at: Point(x: x + border.tlCorner.maxWidth, y: 0))
                    } else if x >= leftWidth + titleLabelWidth - 1 {
                        buffer.write(
                            border.topSide, at: Point(x: x + border.tlCorner.maxWidth, y: 0))
                    }
                    buffer.write(
                        border.bottomSide,
                        at: Point(
                            x: x + border.tlCorner.maxWidth,
                            y: viewport.frame.size.height - border.topSide.countLines))
                    x += border.topSide.maxWidth
                }
                buffer.write(
                    title,
                    at: Point(
                        x: border.tlCorner.maxWidth + leftWidth + border.rightCap.maxWidth + 1,
                        y: titleY), attributes: [.underline])
            } else {
                var x = 0
                while x < innerBorderSize.width {
                    guard x < viewport.mask.maxX else { break }
                    if x + border.topSide.maxWidth >= viewport.mask.x {
                        buffer.write(border.topSide, at: Point(x: x + border.tlCorner.maxWidth, y: 0))
                        buffer.write(
                            border.bottomSide,
                            at: Point(
                                x: x + border.tlCorner.maxWidth,
                                y: viewport.frame.size.height - border.topSide.countLines))
                    }
                    x += border.topSide.maxWidth
                }
            }

            var y = 0
            while y < innerBorderSize.height {
                guard y < viewport.mask.maxY else { break }
                if y + border.leftSide.countLines >= viewport.mask.y {
                    buffer.write(border.leftSide, at: Point(x: 0, y: y + border.tlCorner.countLines))
                    buffer.write(
                        border.rightSide,
                        at: Point(
                            x: viewport.frame.size.width - border.rightSide.maxWidth,
                            y: y + border.tlCorner.countLines
                        ))
                }
                y += border.leftSide.countLines
            }

            let innerOffset = Point(
                x: max(
                    border.tlCorner.maxWidth, border.leftSide.maxWidth, border.blCorner.maxWidth),
                y: max(
                    border.tlCorner.countLines, border.topSide.countLines,
                    border.trCorner.countLines))
            buffer.render(
                key: "Box", view: framedInside,
                viewport: Viewport(Rect(origin: innerOffset, size: innerVisibleSize))
            )
        },
        events: { event, buffer in
            buffer.events(key: "Box", event: event, view: framedInside)
        }
    )
}

public struct BoxBorder {
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
    let leftSide: String
    let rightSide: String

    public init(
        dot: String? = nil,
        topCap: String? = nil,
        bottomCap: String? = nil,
        leftCap: String? = nil,
        rightCap: String? = nil,
        tlCorner: String,
        trCorner: String,
        blCorner: String,
        brCorner: String,
        tbSide: String = "",
        topSide: String? = nil,
        bottomSide: String? = nil,
        lrSide: String = "",
        leftSide: String? = nil,
        rightSide: String? = nil
    ) {
        self.tlCorner = tlCorner
        self.trCorner = trCorner
        self.blCorner = blCorner
        self.brCorner = brCorner

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

    public static let lame = BoxBorder(
        tlCorner: "+",
        trCorner: "+",
        blCorner: "+",
        brCorner: "+",
        tbSide: "-",
        lrSide: "|"
    )
    public static let fancy = BoxBorder(
        leftCap: """
            ┌
            ╞
            ╵
            """,
        rightCap: """
            ┐
            ╡
            ╵
            """,
        tlCorner: """
            ┌╥╥
            ╞╝╚
            ╞╗•
            """,
        trCorner: """
            ╥╥┐
            ╝╚╡
            •╔╡
            """,
        blCorner: """
            ╞╝•
            ╞╗╔
            └╨╨
            """,
        brCorner: """
            •╚╡
            ╗╔╡
            ╨╨┘
            """,
        topSide: """
            ──
            ╗╔
            ╙╜
            """,
        bottomSide: """
            ╓╖
            ╝╚
            ──
            """,
        leftSide: """
            │╚╕
            │╔╛
            """,
        rightSide: """
            ╒╝│
            ╘╗│
            """
    )
    public static let single = BoxBorder(
        dot: "◻︎",
        topCap: "╵",
        bottomCap: "╷",
        leftCap: "╶",
        rightCap: "╴",
        tlCorner: "┌",
        trCorner: "┐",
        blCorner: "└",
        brCorner: "┘",
        tbSide: "─",
        lrSide: "│"
    )
    public static let double = BoxBorder(
        dot: "⧈",
        topCap: "╦",
        bottomCap: "╩",
        leftCap: "╠",
        rightCap: "╣",
        tlCorner: "╔",
        trCorner: "╗",
        blCorner: "╚",
        brCorner: "╝",
        tbSide: "═",
        lrSide: "║"
    )
    public static let doubleSides = BoxBorder(
        dot: "◫",
        topCap: "╥",
        bottomCap: "╨",
        leftCap: "╟",
        rightCap: "╢",
        tlCorner: "╓",
        trCorner: "╖",
        blCorner: "╙",
        brCorner: "╜",
        tbSide: "─",
        lrSide: "║"
    )
    public static let doubleTops = BoxBorder(
        dot: "⊟",
        topCap: "╤",
        bottomCap: "╧",
        leftCap: "╞",
        rightCap: "╡",
        tlCorner: "╒",
        trCorner: "╕",
        blCorner: "╘",
        brCorner: "╛",
        tbSide: "═",
        lrSide: "│"
    )
    public static let rounded = BoxBorder(
        dot: "▢",
        topCap: "╷",
        bottomCap: "╵",
        leftCap: "╶",
        rightCap: "╴",
        tlCorner: "╭",
        trCorner: "╮",
        blCorner: "╰",
        brCorner: "╯",
        tbSide: "─",
        lrSide: "│"
    )
    public static let bold = BoxBorder(
        dot: "◼︎",
        topCap: "╻",
        bottomCap: "╹",
        leftCap: "╺",
        rightCap: "╸",
        tlCorner: "┏",
        trCorner: "┓",
        blCorner: "┗",
        brCorner: "┛",
        tbSide: "━",
        lrSide: "┃"
    )
}
