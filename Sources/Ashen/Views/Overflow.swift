////
///  Overflow.swift
//

public enum OverflowOption {
    case orientation(Orientation)
}

public func Overflow<Msg>(_ view: View<Msg>, _ options: OverflowOption...) -> View<Msg> {
    var orientation: Orientation = .vertical
    for opt in options {
        switch opt {
        case let .orientation(orientationOpt):
            orientation = orientationOpt
        }
    }
    return View(
        preferredSize: { size in
            if orientation == .vertical {
                let newSize = Size(width: (size.width - 1) / 2, height: size.height * 2)
                let preferredSize = view.preferredSize(newSize)
                return Size(width: size.width, height: max(preferredSize.height, size.height))
            } else {
                let newSize = Size(width: size.width * 2, height: (size.height - 1) / 2)
                let preferredSize = view.preferredSize(newSize)
                return Size(width: max(preferredSize.width, size.width), height: size.height)
            }
        },
        render: { viewport, buffer in
            let frameSize = viewport.size

            if orientation == .vertical {
                let x = frameSize.width / 2
                for y in 0 ..< frameSize.height {
                    buffer.write("|", at: Point(x: x, y: y))
                }
            } else {
                let y = frameSize.height / 2
                for x in 0 ..< frameSize.width {
                    buffer.write("-", at: Point(x: x, y: y))
                }
            }

            let modifiedSize: Size
            if orientation == .vertical {
                modifiedSize = Size(width: (frameSize.width - 1) / 2, height: frameSize.height * 2)
            } else {
                modifiedSize = Size(width: frameSize.width * 2, height: (frameSize.height - 1) / 2)
            }

            let modifiedViewport = LocalViewport(size: modifiedSize, visible: Rect(origin: .zero, size: modifiedSize))
            let modifiedBuffer = Buffer(size: modifiedSize, prev: nil)
            view.render(modifiedViewport, modifiedBuffer)

            if orientation == .vertical {
                let halfSize = Size(width: (frameSize.width - 1) / 2, height: frameSize.height)
                let topRect = Rect(origin: .zero, size: halfSize)
                let bottomRect = Rect(origin: Point(x: 0, y: frameSize.height), size: halfSize)
                let extendedRect = Rect(origin: Point(x: halfSize.width + 2, y: 0), size: halfSize)
                modifiedBuffer.copy(into: buffer, from: topRect, at: .zero)
                modifiedBuffer.copy(into: buffer, from: bottomRect, at: extendedRect.origin)
                buffer.store(extendedRect)
            } else {
                let halfSize = Size(width: frameSize.width, height: (frameSize.height - 1) / 2)
                let leftRect = Rect(origin: .zero, size: halfSize)
                let rightRect = Rect(origin: Point(x: frameSize.width, y: 0), size: halfSize)
                let extendedRect = Rect(origin: Point(x: 0, y: halfSize.height + 1), size: halfSize)
                modifiedBuffer.copy(into: buffer, from: leftRect, at: .zero)
                modifiedBuffer.copy(into: buffer, from: rightRect, at: extendedRect.origin)
                buffer.store(extendedRect)
            }
        },
        events: { event, buffer in
            view.events(event, buffer)
        },
        debugName: "Overflow"
    )
}
