////
///  Structs.swift
//


public struct Size: Equatable {
    public var width: Int
    public var height: Int

    public init(width: Int = 0, height: Int = 0) {
        self.width = width
        self.height = height
    }

    public static let zero = Size(width: 0, height: 0)
    public static let max = Size(width: Int.max, height: Int.max)

    public static func == (lhs: Size, rhs: Size) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
    public static func + (lhs: Size, rhs: Size) -> Size {
        return Size(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    public static func - (lhs: Size, rhs: Size) -> Size {
        return Size(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    public static func + (lhs: Size, rhs: Point) -> Size {
        return Size(width: lhs.width + rhs.x, height: lhs.height + rhs.y)
    }
    public static func - (lhs: Size, rhs: Point) -> Size {
        return Size(width: lhs.width - rhs.x, height: lhs.height - rhs.y)
    }
}

public struct Point: Equatable {
    public var x: Int
    public var y: Int

    public init(x: Int = 0, y: Int = 0) {
        self.x = x
        self.y = y
    }

    public static let zero = Point(x: 0, y: 0)
    public static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    public static func + (lhs: Point, rhs: Point) -> Point {
        return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    public static func - (lhs: Point, rhs: Point) -> Point {
        return Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

public struct Rect {
    var origin: Point
    var size: Size

    public init(origin: Point = .zero, size: Size = .zero) {
        self.origin = origin
        self.size = size
    }

    public static let zero = Rect(origin: .zero, size: .zero)

    public var minX: Int { return min(origin.x, origin.x + size.width) }
    public var minY: Int { return min(origin.y, origin.y + size.height) }
    public var maxX: Int { return max(origin.x, origin.x + size.width) }
    public var maxY: Int { return max(origin.y, origin.y + size.height) }
    public var width: Int { return max(size.width, -size.width) }
    public var height: Int { return max(size.height, -size.height) }

    public func intersection(_ other: Rect) -> Rect? {
        let x0 = max(minX, other.minX)
        let x1 = min(maxX, other.maxX)
        if x1 <= x0 { return nil }

        let y0 = max(minY, other.minY)
        let y1 = min(maxY, other.maxY)
        if y1 <= y0 { return nil }

        return Rect(origin: Point(x: x0, y: y0), size: Size(width: x1 - x0, height: y1 - y0))
    }

    public static func + (lhs: Rect, rhs: Point) -> Rect {
        return Rect(origin: lhs.origin + rhs, size: lhs.size)
    }
    public static func - (lhs: Rect, rhs: Point) -> Rect {
        return Rect(origin: lhs.origin - rhs, size: lhs.size)
    }
}

public enum Location {
    public static func at(x: Int = 0, y: Int = 0) -> Location { return .tl(Point(x: x, y: y)) }
    public static func at(_ point: Point) -> Location { return .tl(point) }
    public static func topLeft(x: Int = 0, y: Int = 0) -> Location { return .tl(Point(x: x, y: y)) }
    public static func topLeft(_ point: Point) -> Location { return .tl(point) }
    public static func topCenter(x: Int = 0, y: Int = 0) -> Location { return .tc(Point(x: x, y: y)) }
    public static func top(x: Int = 0, y: Int = 0) -> Location { return .tc(Point(x: x, y: y)) }
    public static func topCenter(_ point: Point) -> Location { return .tc(point) }
    public static func top(_ point: Point) -> Location { return .tc(point) }
    public static func topRight(x: Int = 0, y: Int = 0) -> Location { return .tr(Point(x: x, y: y)) }
    public static func topRight(_ point: Point) -> Location { return .tr(point) }
    public static func middleLeft(x: Int = 0, y: Int = 0) -> Location { return .ml(Point(x: x, y: y)) }
    public static func middleLeft(_ point: Point) -> Location { return .ml(point) }
    public static func middleCenter(x: Int = 0, y: Int = 0) -> Location { return .mc(Point(x: x, y: y)) }
    public static func center(x: Int = 0, y: Int = 0) -> Location { return .mc(Point(x: x, y: y)) }
    public static func middleCenter(_ point: Point) -> Location { return .mc(point) }
    public static func center(_ point: Point) -> Location { return .mc(point) }
    public static func middleRight(x: Int = 0, y: Int = 0) -> Location { return .mr(Point(x: x, y: y)) }
    public static func middleRight(_ point: Point) -> Location { return .mr(point) }
    public static func bottomLeft(x: Int = 0, y: Int = 0) -> Location { return .bl(Point(x: x, y: y)) }
    public static func bottomLeft(_ point: Point) -> Location { return .bl(point) }
    public static func bottomCenter(x: Int = 0, y: Int = 0) -> Location { return .bc(Point(x: x, y: y)) }
    public static func bottom(x: Int = 0, y: Int = 0) -> Location { return .bc(Point(x: x, y: y)) }
    public static func bottomCenter(_ point: Point) -> Location { return .bc(point) }
    public static func bottom(_ point: Point) -> Location { return .bc(point) }
    public static func bottomRight(x: Int = 0, y: Int = 0) -> Location { return .br(Point(x: x, y: y)) }
    public static func bottomRight(_ point: Point) -> Location { return .br(point) }

    case tl(Point)
    case tc(Point)
    case tr(Point)
    case ml(Point)
    case mc(Point)
    case mr(Point)
    case bl(Point)
    case bc(Point)
    case br(Point)

    func origin(for mySize: Size, in size: Size) -> Point {
        switch self {
        case let .tl(point): return point
        case let .tc(point): return Point(x: point.x + (size.width - mySize.width) / 2, y: point.y)
        case let .tr(point): return Point(x: point.x + size.width - mySize.width, y: point.y)
        case let .ml(point): return Point(x: point.x, y: point.y + (size.height - mySize.height) / 2)
        case let .mc(point): return Point(x: point.x + (size.width - mySize.width) / 2, y: point.y + (size.height - mySize.height) / 2)
        case let .mr(point): return Point(x: point.x + size.width - mySize.width, y: point.y + (size.height - mySize.height) / 2)
        case let .bl(point): return Point(x: point.x, y: point.y + size.height - mySize.height)
        case let .bc(point): return Point(x: point.x + (size.width - mySize.width) / 2, y: point.y + size.height - mySize.height)
        case let .br(point): return Point(x: point.x + size.width - mySize.width, y: point.y + size.height - mySize.height)
        }
    }
}
