////
///  Viewport.swift
//

public struct Viewport: Equatable {
    public let frame: Rect
    public let visible: Rect

    public init(_ size: Size) {
        self.init(Rect(origin: .zero, size: size))
    }

    public init(_ frame: Rect) {
        self.init(frame: frame, visible: frame)
    }

    public init(frame: Rect, visible: Rect) {
        self.frame = frame
        self.visible = visible
    }

    public var isEmpty: Bool {
        frame.size.isEmpty || visible.size.isEmpty
    }

    public static let zero: Viewport = Viewport(frame: .zero, visible: .zero)

    public func toLocalViewport() -> LocalViewport {
        return LocalViewport(
            size: frame.size,
            visible: Rect(origin: visible.origin - frame.origin, size: visible.size)
        )
    }

    public static func == (lhs: Viewport, rhs: Viewport) -> Bool {
        lhs.frame == rhs.frame && lhs.visible == rhs.visible
    }
}
