////
///  GridLayout.swift
//


/// Usage:
///     GridLayout(location, size, rows: [
///         .row(weight: .relative(n), [
///             .column(weight: .relative(n), ComponentView),
///             .column(ComponentView),  // default weight is 1
///         ]),
///         .row(weight: .fixed(2)),  // blank row, e.g. padding
///         .row([  // default weight is 1
///             .column(ComponentView),
///         ]),
///     ])
class GridLayout: ComponentLayout {
    enum Weight {
        case fixed(Int)
        case relative(Float)
    }

    struct Row {
        static func row(weight: Weight = .relative(1), _ columns: [Column] = []) -> Row {
            return Row(weight: weight, columns: columns)
        }
        static func row(weight: Weight = .relative(1), _ components: [ComponentView] = []) -> Row {
            return Row(weight: weight, columns: components.map { .column($0) })
        }
        let weight: Weight
        let columns: [Column]
    }

    struct Column {
        static func column(weight: Weight = .relative(1), _ component: ComponentView) -> Column {
            return Column(weight: weight, component: component)
        }
        let weight: Weight
        let component: ComponentView
    }

    let rows: [Row]
    let size: Size

    private static func totalWeight(_ weights: [Weight]) -> Float {
        return weights.reduce(0 as Float) { memo, weight in
            if case let .relative(value) = weight {
                return memo + value
            }
            return memo
        }
    }

    init(_ location: Location = .tl(.zero), _ size: Size, rows: [Row]) {
        self.size = size
        self.rows = rows
        super.init()
        self.components = rows.flatMap { $0.columns.map { $0.component } }
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(size)
    }

    private static func calculateDimensions(screen: Int, weights: [Weight]) -> [Int] {
        var remaining = screen
        var relative = screen
        for weight in weights {
            if case let .fixed(value) = weight {
                relative = max(0, relative - value)
            }
        }

        var calculations: [Int] = weights.map { weight in
            var calculated = 0
            switch weight {
            case let .fixed(value):
                calculated = value
            case let .relative(value):
                calculated = Int(value * Float(relative) / totalWeight(weights))
            }

            remaining -= calculated
            return calculated
        }

        if remaining != 0 {
            let relativeWeights = weights.enumerated().flatMap { (offset, weight) -> (Int, Float)? in
                if case let .relative(value) = weight { return (offset, value) }
                return nil
            }
            let sortedOffsets = relativeWeights.sorted(by: { a, b in
                return a.1 < b.1
            }).map({ $0.0 })
            for offset in sortedOffsets {
                guard remaining != 0 else { break }
                if remaining > 0 {
                    calculations[offset] += 1
                    remaining -= 1
                }
                else {
                    calculations[offset] -= 1
                    remaining += 1
                }
            }
        }

        return calculations
    }

    override func render(in buffer: Buffer, size screenSize: Size) {
        var offset: Point = .zero
        let calculatedRowHeights = GridLayout.calculateDimensions(screen: screenSize.height, weights: rows.map { $0.weight })
        for (rowIndex, row) in rows.enumerated() {
            let rowHeight = calculatedRowHeights[rowIndex]
            guard rowHeight > 0 else { continue }

            let calculatedColWidths = GridLayout.calculateDimensions(screen: screenSize.width, weights: row.columns.map { $0.weight })
            for (colIndex, column) in row.columns.enumerated() {
                let colWidth = calculatedColWidths[colIndex]
                guard colWidth > 0 else { continue }

                let view = column.component
                let viewSize = Size(width: colWidth, height: rowHeight)
                buffer.push(offset: offset, clip: viewSize) {
                    view.render(in: buffer, size: viewSize)
                }
                offset.x += colWidth
            }

            offset.x = 0
            offset.y += rowHeight
        }
    }
}
