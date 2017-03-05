////
///  GridLayout.swift
//


/// Usage:
///     GridLayout(location, size, rows: [
///         .row(weight: n, [
///             .column(weight: n, ComponentView),
///             .column(ComponentView),  // default weight is 1
///         ]),
///         .row(weight: 2),  // blank row, e.g. padding
///         .row([  // default weight is 1
///             .column(ComponentView),
///         ]),
///     ])
class GridLayout: ComponentLayout {
    struct Row {
        static func row(weight: Float = 1, _ columns: [Column] = []) -> Row {
            return Row(weight: weight, columns: columns)
        }
        let weight: Float
        let columns: [Column]
    }

    struct Column {
        static func column(weight: Float = 1, _ component: ComponentView) -> Column {
            return Column(weight: weight, component: component)
        }
        let weight: Float
        let component: ComponentView
    }

    let rows: [Row]
    let size: Size

    var totalRowWeight: Float { return rows.reduce(0 as Float) { $0 + $1.weight } }
    func totalColumnWeight(at index: Int) -> Float {
        return rows[index].columns.reduce(0 as Float) { $0 + $1.weight }
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

    override func chars(in screenSize: Size) -> Screen.Chars {
        var offset: Point = .zero
        var chars: Screen.Chars = [:]
        for (rowIndex, row) in rows.enumerated() {
            let rowHeight = Int(row.weight * Float(screenSize.height) / totalRowWeight + 0.5)
            let totalColumnWeight = self.totalColumnWeight(at: rowIndex)
            for (colIndex, column) in row.columns.enumerated() {
                let colWidth: Int
                if colIndex == row.columns.count - 1 {
                    colWidth = screenSize.width - offset.x
                }
                else {
                    colWidth = Int(column.weight * Float(screenSize.width) / totalColumnWeight)
                }

                let view = column.component
                let viewSize = Size(width: colWidth, height: rowHeight)
                let viewChars = view.chars(in: viewSize)
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

                offset.x += colWidth
            }

            offset.x = 0
            offset.y += rowHeight
        }

        return chars
    }
}
