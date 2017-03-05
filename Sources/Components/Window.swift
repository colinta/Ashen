////
///  Window.swift
//


class Window: ComponentLayout {

    convenience init(components: [Component]) {
        self.init()
        self.components = components
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: Int.max, height: Int.max)
    }

    static func chars(components: [Component], in screenSize: Size) -> Screen.Chars {
        var chars: Screen.Chars = [:]
        for view in components {
            guard let view = view as? ComponentView else { continue }

            let viewSize = view.desiredSize().constrain(in: screenSize)
            let viewChars = view.chars(in: viewSize)
            let offset = view.location.origin(for: viewSize, in: screenSize)
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
