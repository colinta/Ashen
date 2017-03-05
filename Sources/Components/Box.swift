////
///  Box.swift
//

class Box: ComponentLayout {
    indirect enum Border {
        case lame
        case single
        case double
        case mixed
    }

    let size: Size
    let border: Border?
    let background: TextType?

    init(_ location: Location, _ size: Size, border: Border? = nil, background: TextType? = nil, components: [Component]) {
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

    override func chars(in screenSize: Size) -> Screen.Chars {
        var chars: Screen.Chars = [:]
        let size: Size
        if border == nil {
            size = screenSize
        }
        else {
            size = Size(width: max(0, screenSize.width - 2), height: max(0, screenSize.height - 2))
        }

        if let background = background, size.height > 0 && size.width > 0 {
            for y in 0 ..< screenSize.height {
                var newRow = chars[y] ?? [:]
                for x in 0 ..< screenSize.width {
                    newRow[x] = background
                }
                chars[y] = newRow
            }
        }

        for view in components {
            guard let view = view as? ComponentView else { continue }

            let viewSize = view.desiredSize().constrain(in: size)
            let viewChars = view.chars(in: viewSize)
            var offset = view.location.origin(for: viewSize, in: size)
            if border != nil {
                offset.x += 1
                offset.y += 1
            }
            for (y, row) in viewChars {
                var newRow = chars[offset.y + y] ?? [:]
                for (x, c) in row {
                    newRow[offset.x + x] = c
                }
                chars[y] = newRow
            }
        }

        // if let border = border {
        // }
        return chars
    }
}

extension Box.Border {
    var tl: String { return "+" }
    var tr: String { return "+" }
    var bl: String { return "+" }
    var br: String { return "+" }
    var t: String { return "-" }
    var b: String { return "-" }
    var l: String { return "|" }
    var r: String { return "|" }
}
