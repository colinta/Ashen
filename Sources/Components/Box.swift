////
///  Box.swift
//

class Box: ComponentLayoutType {
    indirect enum Border {
        case lame
        case single
        case double
        case mixed
    }

    let size: Size
    let border: Border?

    init(_ location: Location, _ size: Size, border: Border? = nil, components: [ComponentType]) {
        self.size = size
        self.border = border
        super.init()
        self.components = components
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: size.width, height: size.height)
    }

    override func chars(in screenSize: Size) -> Screen.Chars {
        var chars: Screen.Chars = [:]
        let size: Size
        if border == nil {
            size = self.size
        }
        else {
            size = Size(width: max(0, self.size.width - 2), height: max(0, self.size.height - 2))
        }

        for view in components {
            guard let view = view as? ComponentViewType else { continue }

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
