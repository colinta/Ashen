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

    override func render(in buffer: Buffer, size screenSize: Size) {
        let size: Size
        let borderOffset: Point
        if border == nil {
            borderOffset = .zero
            size = screenSize
        }
        else {
            borderOffset = Point(x: 1, y: 1)
            size = Size(width: max(0, screenSize.width - 2), height: max(0, screenSize.height - 2))
        }

        if let background = background, size.height > 0 && size.width > 0 {
            for y in 0 ..< size.height {
                for x in 0 ..< size.width {
                    buffer.write(background, x: x, y: y)
                }
            }
        }

        for view in components {
            guard let view = view as? ComponentView else { continue }

            let viewSize = view.desiredSize().constrain(in: size)
            let viewOffset = view.location.origin(for: viewSize, in: size)
            let offset = Point(
                x: viewOffset.x + borderOffset.x,
                y: viewOffset.y + borderOffset.y
                )
            buffer.push(offset: offset) {
                view.render(in: buffer, size: viewSize)
            }
        }

        if let border = border {
        }
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
