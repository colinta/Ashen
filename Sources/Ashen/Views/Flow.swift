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
    Flow(.leftToRight, views.map { (.flex1, $0) })
}

public func Rows<Msg>(_ views: [View<Msg>]) -> View<Msg> {
    Flow(.topToBottom, views.map { (.flex1, $0) })
}

public func Stack<Msg>(_ direction: FlowDirection, _ views: [View<Msg>]) -> View<Msg> {
    Flow(direction, views.map { (.fixed, $0) })
}

public func Flow<Msg>(_ direction: FlowDirection, _ views: [(FlowSize, View<Msg>)]) -> View<Msg> {
    View<Msg>(
        preferredSize: { parentSize in
            var allSizes: Size = .zero
            var maxWidth = 0
            var maxHeight = 0
            var remainingSize = parentSize
            for (flowSize, view) in views {
                let preferredSize = view.preferredSize(remainingSize)
                maxWidth = max(maxWidth, preferredSize.width)
                maxHeight = max(maxHeight, preferredSize.height)
                if case .fixed = flowSize {
                    allSizes = allSizes + preferredSize
                    if direction.isHorizontal {
                        remainingSize = remainingSize - Size(width: preferredSize.width, height: 0)
                    } else {
                        remainingSize = remainingSize - Size(width: 0, height: preferredSize.height)
                    }
                }
                else if direction.isHorizontal {
                    remainingSize = Size(width: 0, height: remainingSize.height)
                    allSizes = Size(width: parentSize.width, height: allSizes.height)
                    break
                }
                else {
                    remainingSize = Size(width: remainingSize.width, height: 0)
                    allSizes = Size(width: allSizes.width, height: parentSize.height)
                    break
                }
            }

            if direction.isHorizontal {
                return Size(
                    width: min(parentSize.width, allSizes.width),
                    height: min(parentSize.height, maxHeight)
                )
            } else {
                return Size(
                    width: min(parentSize.width, maxWidth),
                    height: min(parentSize.height, allSizes.height)
                )
            }
        },
        render: { rect, buffer in
            var remainingSize = rect.size
            var flexTotal: Float = 0
            var preferredSizes: [Int: Size] = [:]
            var lastFlexIndex = 0
            for (index, (flowSize, view)) in views.enumerated() {
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
                cursor = Point(x: rect.width, y: 0)
            case .bottomToTop:
                cursor = Point(x: 0, y: rect.height)
            }

            for (index, (flowSize, view)) in views.enumerated() {
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
                        viewSize = Size(width: width, height: rect.height)
                        remainingFlexSize = remainingFlexSize - Size(width: width, height: 0)
                    } else {
                        let height =
                            isLast
                            ? remainingFlexSize.height
                            : Int((flexPercent * Float(startingFlexSize.height)).rounded())
                        viewSize = Size(width: rect.width, height: height)
                        remainingFlexSize = remainingFlexSize - Size(width: 0, height: height)
                    }
                case .fixed:
                    if direction.isHorizontal {
                        viewSize = Size(
                            width: preferredSizes[index]!.width, height: rect.height)
                    } else {
                        viewSize = Size(
                            width: rect.width, height: preferredSizes[index]!.height)
                    }
                }

                if case .rightToLeft = direction {
                    cursor = cursor - Point(x: viewSize.width, y: 0)
                } else if case .bottomToTop = direction {
                    cursor = cursor - Point(x: 0, y: viewSize.height)
                }

                buffer.render(
                    key: index, view: view, at: cursor,
                    clip: viewSize)

                if case .leftToRight = direction {
                    cursor = cursor + Point(x: viewSize.width, y: 0)
                } else if case .topToBottom = direction {
                    cursor = cursor + Point(x: 0, y: viewSize.height)
                }
            }
        },
        events: { event, buffer in
            views.enumerated().reduce(([Msg](), [Event]())) { info, index_view in
                let (msgs, events) = info
                let (index, view) = (index_view.0, index_view.1.1)
                let (newMsgs, newEvents) = buffer.events(key: index, event: event, view: view)
                return (msgs + newMsgs, events + newEvents)
            }
        }
    )
}
