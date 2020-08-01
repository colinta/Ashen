////
///  Rect.swift
//

public struct Rect: Equatable {
    public let origin: Point
    public let size: Size

    public var x: Int { origin.x }
    public var y: Int { origin.y }
    public var width: Int { size.width }
    public var height: Int { size.height }

    public static let zero = Rect(origin: .zero, size: .zero)

    public func at(x: Int, y: Int) -> Rect {
        Rect(origin: Point(x: x, y: y), size: size)
    }

    public func shrink(by: Int) -> Rect {
        grow(width: -by, height: -by)
    }

    public func grow(by: Int) -> Rect {
        grow(width: by, height: by)
    }

    public func shrink(width: Int, height: Int) -> Rect {
        grow(width: -width, height: -height)
    }

    public func grow(width dw: Int, height dh: Int) -> Rect {
        Rect(origin: origin, size: size.grow(width: dw, height: dh))
    }

    public static func == (lhs: Rect, rhs: Rect) -> Bool {
        lhs.size == rhs.size && lhs.origin == rhs.origin
    }
    public static func + (lhs: Rect, rhs: Point) -> Rect {
        Rect(origin: lhs.origin + rhs, size: lhs.size)
    }
    public static func - (lhs: Rect, rhs: Point) -> Rect {
        Rect(origin: lhs.origin - rhs, size: lhs.size)
    }
    public static func + (lhs: Rect, rhs: Size) -> Rect {
        Rect(origin: lhs.origin, size: lhs.size + rhs)
    }
    public static func - (lhs: Rect, rhs: Size) -> Rect {
        Rect(origin: lhs.origin, size: lhs.size - rhs)
    }
}
