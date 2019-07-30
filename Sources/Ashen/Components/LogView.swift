////
///  LogView.swift
//

public class LogView: ComponentLayout {
    let size: DesiredSize
    let entries: [String]

    public init(at location: Location = .tl(.zero), size: DesiredSize = DesiredSize(), entries: [String]) {
        self.entries = entries
        self.size = size
        super.init()
        self.location = location
        var y = 0
        components = entries.map { entry in
            let component = LabelView(at: .topLeft(y: y), text: entry)
            y += 1
            return component
        }
    }

    override func desiredSize() -> DesiredSize {
        guard size.width == nil || size.height == nil else {
            return size
        }

        let maxSize = entries.reduce(Size.zero) { _maxSize, entry in
            let lines = entry.split(separator: "\n")
            return lines.reduce(_maxSize) { maxSize, line in
                return Size(
                    width: max(maxSize.width, line.count),
                    height: maxSize.height + lines.count
                    )
            }
        }

        let desiredWidth = size.width ?? .literal(maxSize.width)
        let desiredHeight = size.height ?? .literal(maxSize.height)
        return DesiredSize(width: desiredWidth, height: desiredHeight)
    }

    override func render(to buffer: Buffer, in rect: Rect) {
        let entriesHeight = entries.reduce(0) { maxHeight, entry in
            let lines = entry.split(separator: "\n")
            return maxHeight + lines.count
        }
        let offset = max(0, entriesHeight - rect.size.height)
        let innerRect = Rect(
            origin: rect.origin + Point(y: offset),
            size: rect.size
            )
        super.render(to: buffer, in: innerRect)
    }
}
