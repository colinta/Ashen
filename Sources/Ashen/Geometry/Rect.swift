////
///  Rect.swift
//

public struct Rect: Equatable {
    public let origin: Point
    public let size: Size

    public var minX: Int { origin.x }
    public var maxX: Int { origin.x + size.width }
    public var minY: Int { origin.y }
    public var maxY: Int { origin.y + size.height }
    public var width: Int { size.width }
    public var height: Int { size.height }

    public static let zero = Rect(origin: .zero, size: .zero)

    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

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

    public func contains(_ point: Point) -> Bool {
        point.x >= minX && point.x < maxX &&
        point.y >= minY && point.y < maxY
    }

    public func intersection(with rect: Rect) -> Rect {
        let x0 = max(minX, rect.minX)
        let x1 = min(maxX, rect.maxX)
        let y0 = max(minY, rect.minY)
        let y1 = min(maxY, rect.maxY)
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
