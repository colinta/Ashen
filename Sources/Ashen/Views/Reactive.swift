////
///  Reactive.swift
//

public func Reactive<Msg>(_ views: [View<Msg>]) -> View<Msg> {
    View<Msg>(
        preferredSize: { parentSize in
            let maxHeight = calculateMaxHeight(views, inSize: parentSize)
            return Size(width: parentSize.width, height: maxHeight)
        },
        render: { viewport, buffer in
            let (viewsAndSizes, columnCount, idealHeight) = calculateSizes(
                views, inSize: viewport.size)
            guard columnCount > 0 else { return }

            var columnWidth = viewport.size.width / columnCount
            var currentHeight = 0
            var columnIndex = 0
            var origin: Point = .zero
            for (index, view_size) in viewsAndSizes.enumerated() {
                let (view, preferredSize) = view_size
                buffer.render(
                    key: index, view: view,
                    viewport: Viewport(
                        Rect(
                            origin: origin,
                            size: Size(width: columnWidth, height: preferredSize.height))))

                currentHeight += preferredSize.height
                if currentHeight >= idealHeight {
                    origin = Point(x: origin.x + columnWidth, y: 0)
                    currentHeight = 0
                    columnIndex += 1
                    columnWidth = viewport.size.width - (columnWidth * (columnCount - 1))
                } else {
                    origin = Point(x: origin.x, y: origin.y + preferredSize.height)
                }
            }
        },
        events: { event, buffer in
            View.scan(views: views, event: event, buffer: buffer)
        },
        debugName: "Reactive"
    )
}

private func calculateSizes<Msg>(_ views: [View<Msg>], inSize parentSize: Size) -> (
    [(View<Msg>, Size)], Int, Int
) {
    var maxWidth = 0
    var totalHeight = 0
    var viewsAndSizes: [(View<Msg>, Size)] = []
    var remainingSize = parentSize
    for view in views {
        let preferredSize = view.preferredSize(remainingSize)
        viewsAndSizes.append((view, preferredSize))
        maxWidth = max(maxWidth, preferredSize.width)
        totalHeight += preferredSize.height
        remainingSize = remainingSize.shrink(height: preferredSize.height)
    }

    if maxWidth > 0 {
        let columnCount = max(1, parentSize.width / maxWidth)
        let idealHeight = Int((Float(totalHeight) / Float(columnCount)).rounded(.up))
        return (viewsAndSizes, columnCount, idealHeight)
    } else {
        return (viewsAndSizes, 0, totalHeight)
    }
}

private func calculateMaxHeight<Msg>(_ views: [View<Msg>], inSize parentSize: Size) -> Int {
    let (viewsAndSizes, _, idealHeight) = calculateSizes(views, inSize: parentSize)

    var maxHeight = 0
    var currentHeight = 0
    for (_, preferredSize) in viewsAndSizes {
        currentHeight += preferredSize.height
        if currentHeight >= idealHeight {
            maxHeight = max(maxHeight, currentHeight)
            currentHeight = 0
        }
    }
    maxHeight = max(maxHeight, currentHeight)
    return maxHeight
}
