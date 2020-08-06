////
///  Rect.swift
//

public struct Rect: Equatable {
    public let origin: Point
    public let size: Size

    public var x: Int { origin.x }
    public var maxX: Int { origin.x + size.width }
    public var y: Int { origin.y }
    public var maxY: Int { origin.y + size.height }
    public var width: Int { size.width }
    public var height: Int { size.height }

    public static let zero = Rect(origin: .zero, size: .zero)

    public func at(x: Int, y: Int) -> Rect {
        Rect(origin: Point(x: x, y: y), size: size)
    }

    public func at(_ origin: Point) -> Rect {
        Rect(origin: origin, size: size)
    }

    public func sized(_ size: Size) -> Rect {
        Rect(origin: origin, size: size)
    }

    public func sized(width: Int) -> Rect {
        Rect(origin: origin, size: Size(width: width, height: height))
    }

    public func sized(height: Int) -> Rect {
        Rect(origin: origin, size: Size(width: width, height: height))
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

    public func intersection(with rect: Rect) -> Rect {
        let x0 = max(x, rect.x)
        let x1 = min(x + width, rect.x + rect.width)
        let y0 = max(y, rect.y)
        let y1 = min(y + height, rect.y + rect.height)
        return Rect(origin: Point(x: x0, y: y0), size: Size(width: x1 - x0, height: y1 - y0))
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
