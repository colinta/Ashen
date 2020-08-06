////
///  LocalViewport.swift
//

public struct LocalViewport: Equatable {
    public let size: Size
    public let mask: Rect

    public init(_ size: Size) {
        self.init(size: size, mask: Rect(origin: .zero, size: size))
    }

    public init(size: Size, mask: Rect) {
        self.size = size
        self.mask = mask
    }

    public var isEmpty: Bool {
        size.isEmpty || mask.size.isEmpty
    }

    public static let zero: LocalViewport = LocalViewport(size: .zero, mask: .zero)

    public func limit(width: Int) -> LocalViewport {
        let maxFrameX = width
        let maxMaskWidth = maxFrameX - mask.minX
        return LocalViewport(
            size: Size(width: min(size.width, width), height: size.height),
            mask: mask.sized(width: min(mask.width, maxMaskWidth))
        )
    }

    public func limit(height: Int) -> LocalViewport {
        let maxFrameY = height
        let maxMaskHeight = maxFrameY - mask.minY
        return LocalViewport(
            size: Size(width: size.width, height: min(size.height, height)),
            mask: mask.sized(height: min(mask.height, maxMaskHeight))
        )
    }

    public func toViewport() -> Viewport {
        return Viewport(
            frame: Rect(origin: .zero, size: size),
            mask: mask
        )
    }

    public static func == (lhs: LocalViewport, rhs: LocalViewport) -> Bool {
        lhs.size == rhs.size && lhs.mask == rhs.mask
    }
}
