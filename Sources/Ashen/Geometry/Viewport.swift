////
///  Viewport.swift
//

public struct Viewport: Equatable {
    public let frame: Rect
    public let mask: Rect

    public init(_ size: Size) {
        self.init(Rect(origin: .zero, size: size))
    }

    public init(_ frame: Rect) {
        self.init(frame: frame, mask: frame)
    }

    public init(frame: Rect, mask: Rect) {
        self.frame = frame
        self.mask = mask
    }

    public var isEmpty: Bool {
        frame.size.isEmpty || mask.size.isEmpty
    }

    public static let zero: Viewport = Viewport(frame: .zero, mask: .zero)

    public func limit(width: Int) -> Viewport {
        let maxFrameX = frame.x + width
        let maxMaskWidth = maxFrameX - mask.x
        return Viewport(
            frame: frame.sized(width: min(frame.width, width)),
            mask: mask.sized(width: min(mask.width, maxMaskWidth))
        )
    }

    public func limit(height: Int) -> Viewport {
        let maxFrameY = frame.y + height
        let maxMaskHeight = maxFrameY - mask.y
        return Viewport(
            frame: frame.sized(height: min(frame.height, height)),
            mask: mask.sized(height: min(mask.height, maxMaskHeight))
        )
    }

    public func toLocalOrigin() -> Viewport {
        return Viewport(
            frame: Rect(origin: .zero, size: frame.size),
            mask: Rect(origin: mask.origin - frame.origin, size: mask.size)
        )
    }

    public static func == (lhs: Viewport, rhs: Viewport) -> Bool {
        lhs.frame == rhs.frame && lhs.mask == rhs.mask
    }
}
