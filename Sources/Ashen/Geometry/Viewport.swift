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

    public func toLocalViewport() -> LocalViewport {
        return LocalViewport(
            size: frame.size,
            mask: Rect(origin: mask.origin - frame.origin, size: mask.size)
        )
    }

    public static func == (lhs: Viewport, rhs: Viewport) -> Bool {
        lhs.frame == rhs.frame && lhs.mask == rhs.mask
    }
}
