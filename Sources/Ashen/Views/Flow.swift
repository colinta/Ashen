////
///  Flow.swift
//

public enum FlowDirection {
    case leftToRight
    case rightToLeft
    case topToBottom
    case bottomToTop

    public static let ltr: FlowDirection = .leftToRight
    public static let rtl: FlowDirection = .rightToLeft
    public static let down: FlowDirection = .topToBottom
    public static let up: FlowDirection = .bottomToTop

    var isHorizontal: Bool {
        switch self {
        case .leftToRight, .rightToLeft:
            return true
        default:
            return false
        }
    }

    var isVertical: Bool {
        return !isHorizontal
    }
}

public enum FlowSize {
    case flex(Float)
    case fixed

    public static let flex1: FlowSize = .flex(1)
}

public func Columns<Msg>(_ views: [View<Msg>]) -> View<Msg> {
    Flow(.leftToRight, views.map { (.flex1, $0) }).debugName("Columns")
}

public func Rows<Msg>(_ views: [View<Msg>]) -> View<Msg> {
    Flow(.topToBottom, views.map { (.flex1, $0) }).debugName("Rows")
}

public func Stack<Msg>(_ direction: FlowDirection, _ views: [View<Msg>]) -> View<Msg> {
    Flow(direction, views.map { (.fixed, $0) }).debugName("Stack")
}

public func Flow<Msg>(_ direction: FlowDirection, _ sizedViews: [(FlowSize, View<Msg>)]) -> View<Msg> {
    View<Msg>(
        preferredSize: { parentSize in
            var allSizes: Size = .zero
            var maxWidth = 0
            var maxHeight = 0
            var remainingSize = parentSize
            var foundFlex = false
            for (flowSize, view) in sizedViews {
                let preferredSize = view.preferredSize(remainingSize)
                maxWidth = max(maxWidth, preferredSize.width)
                maxHeight = max(maxHeight, preferredSize.height)
                if case .fixed = flowSize {
                    if direction.isHorizontal {
                        allSizes = allSizes + Size(width: preferredSize.width, height: 0)
                        remainingSize = remainingSize - Size(width: preferredSize.width, height: 0)
                    } else {
                        allSizes = allSizes + Size(width: 0, height: preferredSize.height)
                        remainingSize = remainingSize - Size(width: 0, height: preferredSize.height)
                    }
                } else if direction.isHorizontal {
                    foundFlex = true
                } else {
                    foundFlex = true
                }
            }

            switch (foundFlex, direction.isHorizontal) {
            case (true, true):
                return Size(
                    width: parentSize.width,
                    height: maxHeight
                )
            case (true, false):
                return Size(
                    width: maxWidth,
                    height: parentSize.height
                )
            case (false, true):
                return Size(
                    width: allSizes.width,
                    height: maxHeight
                )
            case (false, false):
                return Size(
                    width: maxWidth,
                    height: allSizes.height
                )
            }
        },
        render: { viewport, buffer in
            guard !viewport.isEmpty else {
                for (index, (_, view)) in sizedViews.enumerated() {
                    buffer.render(key: index, view: view, viewport: .zero)
                }
                return
            }

            var remainingSize = viewport.size
            var flexTotal: Float = 0
            var preferredSizes: [Int: Size] = [:]
            var lastFlexIndex = 0
            for (index, (flowSize, view)) in sizedViews.enumerated() {
                if case let .flex(flex) = flowSize {
                    flexTotal += flex
                    lastFlexIndex = index
                } else {
                    let preferredSize = view.preferredSize(remainingSize)
                    preferredSizes[index] = preferredSize

                    if direction.isHorizontal {
                        remainingSize = remainingSize - Size(width: preferredSize.width, height: 0)
                    } else {
                        remainingSize = remainingSize - Size(width: 0, height: preferredSize.height)
                    }
                }
            }

            flexTotal = max(flexTotal, 1)

            let startingFlexSize = remainingSize
            var remainingFlexSize = remainingSize
            var cursor: Point
            switch direction {
            case .leftToRight, .topToBottom:
                cursor = .zero
            case .rightToLeft:
                cursor = Point(x: viewport.size.width, y: 0)
            case .bottomToTop:
                cursor = Point(x: 0, y: viewport.size.height)
            }

            for (index, (flowSize, view)) in sizedViews.enumerated() {
                let viewSize: Size
                switch flowSize {
                case let .flex(flex):
                    let isLast = lastFlexIndex == index
                    let flexPercent = flex / flexTotal
                    if direction.isHorizontal {
                        let width =
                            isLast
                            ? remainingFlexSize.width
                            : Int((flexPercent * Float(startingFlexSize.width)).rounded())
                        viewSize = Size(width: width, height: viewport.size.height)
                        remainingFlexSize = remainingFlexSize - Size(width: width, height: 0)
                    } else {
                        let height =
                            isLast
                            ? remainingFlexSize.height
                            : Int((flexPercent * Float(startingFlexSize.height)).rounded())
                        viewSize = Size(width: viewport.size.width, height: height)
                        remainingFlexSize = remainingFlexSize - Size(width: 0, height: height)
                    }
                case .fixed:
                    if direction.isHorizontal {
                        viewSize = Size(
                            width: preferredSizes[index]!.width, height: viewport.size.height)
                    } else {
                        viewSize = Size(
                            width: viewport.size.width, height: preferredSizes[index]!.height)
                    }
                }

                if case .rightToLeft = direction {
                    cursor = cursor - Point(x: viewSize.width, y: 0)
                } else if case .bottomToTop = direction {
                    cursor = cursor - Point(x: 0, y: viewSize.height)
                }

                buffer.render(
                    key: index, view: view, viewport: Viewport(Rect(origin: cursor, size: viewSize))
                )

                if case .leftToRight = direction {
                    cursor = cursor + Point(x: viewSize.width, y: 0)
                } else if case .topToBottom = direction {
                    cursor = cursor + Point(x: 0, y: viewSize.height)
                }
            }
        },
        events: { event, buffer in
            let views = sizedViews.map { $0.1 }
            return View.scan(views: views, event: event, buffer: buffer)
        },
        debugName: "Flow"
    )
}
