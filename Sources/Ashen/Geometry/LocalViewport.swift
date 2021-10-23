////
///  LocalViewport.swift
//

public struct LocalViewport: Equatable {
    public let size: Size
    public let visible: Rect

    public init(_ size: Size) {
        self.init(size: size, visible: Rect(origin: .zero, size: size))
    }

    public init(size: Size, visible: Rect) {
        self.size = size
        self.visible = visible
    }

    public var isEmpty: Bool {
        size.isEmpty || visible.size.isEmpty
    }

    public static let zero: LocalViewport = LocalViewport(size: .zero, visible: .zero)

    public func limit(size: Size) -> LocalViewport {
        let maxFrameX = size.width
        let maxMaskWidth = maxFrameX - visible.minX

        let maxFrameY = size.height
        let maxMaskHeight = maxFrameY - visible.minY

        return LocalViewport(
            size: Size(width: min(self.size.width, size.width), height: min(self.size.height, size.height)),
            visible: visible.sized(Size(
                width: min(visible.width, maxMaskWidth),
                height: min(visible.height, maxMaskHeight)
            ))
        )
    }

    public func limit(width: Int) -> LocalViewport {
        let maxFrameX = width
        let maxMaskWidth = maxFrameX - visible.minX
        return LocalViewport(
            size: Size(width: min(size.width, width), height: size.height),
            visible: visible.sized(width: min(visible.width, maxMaskWidth))
        )
    }

    public func limit(height: Int) -> LocalViewport {
        let maxFrameY = height
        let maxMaskHeight = maxFrameY - visible.minY
        return LocalViewport(
            size: Size(width: size.width, height: min(size.height, height)),
            visible: visible.sized(height: min(visible.height, maxMaskHeight))
        )
    }

    public func toViewport() -> Viewport {
        return Viewport(
            frame: Rect(origin: .zero, size: size),
            visible: visible
        )
    }

    public static func == (lhs: LocalViewport, rhs: LocalViewport) -> Bool {
        lhs.size == rhs.size && lhs.visible == rhs.visible
    }
}
