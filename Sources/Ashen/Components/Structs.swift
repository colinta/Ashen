////
///  Structs.swift
//


public struct Size: Equatable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
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

public struct DesiredSize {
    public var width: Int?
    public var height: Int?

    public init(width: Int? = nil, height: Int? = nil) {
        self.width = width
        self.height = height
    }

    public init(_ size: Size) {
        self.width = size.width
        self.height = size.height
    }

    func constrain(in size: Size, scrollOffset: Point = .zero) -> Size {
        return Size(
            width: min(width ?? 0, size.width),
            height: min(height ?? 0, size.height)
            )
    }
}

public struct Point: Equatable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
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

public struct Frame {
    var origin: Point
    var size: Size
}

public enum Location {
    public static func at(x: Int = 0, y: Int = 0) -> Location { return .tl(Point(x: x, y: y)) }
    public static func at(_ point: Point) -> Location { return .tl(point) }
    public static func topLeft(x: Int = 0, y: Int = 0) -> Location { return .tl(Point(x: x, y: y)) }
    public static func topLeft(_ point: Point) -> Location { return .tl(point) }
    public static func topCenter(x: Int = 0, y: Int = 0) -> Location { return .tc(Point(x: x, y: y)) }
    public static func topCenter(_ point: Point) -> Location { return .tc(point) }
    public static func topRight(x: Int = 0, y: Int = 0) -> Location { return .tr(Point(x: x, y: y)) }
    public static func topRight(_ point: Point) -> Location { return .tr(point) }
    public static func middleLeft(x: Int = 0, y: Int = 0) -> Location { return .ml(Point(x: x, y: y)) }
    public static func middleLeft(_ point: Point) -> Location { return .ml(point) }
    public static func middleCenter(x: Int = 0, y: Int = 0) -> Location { return .mc(Point(x: x, y: y)) }
    public static func middleCenter(_ point: Point) -> Location { return .mc(point) }
    public static func middleRight(x: Int = 0, y: Int = 0) -> Location { return .mr(Point(x: x, y: y)) }
    public static func middleRight(_ point: Point) -> Location { return .mr(point) }
    public static func bottomLeft(x: Int = 0, y: Int = 0) -> Location { return .bl(Point(x: x, y: y)) }
    public static func bottomLeft(_ point: Point) -> Location { return .bl(point) }
    public static func bottomCenter(x: Int = 0, y: Int = 0) -> Location { return .bc(Point(x: x, y: y)) }
    public static func bottomCenter(_ point: Point) -> Location { return .bc(point) }
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

    func origin(for mySize: Size, in screenSize: Size) -> Point {
        switch self {
        case let .tl(point): return point
        case let .tc(point): return Point(x: point.x + (screenSize.width - mySize.width) / 2, y: point.y)
        case let .tr(point): return Point(x: point.x + screenSize.width - mySize.width, y: point.y)
        case let .ml(point): return Point(x: point.x, y: point.y + (screenSize.height - mySize.height) / 2)
        case let .mc(point): return Point(x: point.x + (screenSize.width - mySize.width) / 2, y: point.y + (screenSize.height - mySize.height) / 2)
        case let .mr(point): return Point(x: point.x + screenSize.width - mySize.width, y: point.y + (screenSize.height - mySize.height) / 2)
        case let .bl(point): return Point(x: point.x, y: point.y + screenSize.height - mySize.height)
        case let .bc(point): return Point(x: point.x + (screenSize.width - mySize.width) / 2, y: point.y + screenSize.height - mySize.height)
        case let .br(point): return Point(x: point.x + screenSize.width - mySize.width, y: point.y + screenSize.height - mySize.height)
        }
    }
}
