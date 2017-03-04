////
///  Structs.swift
//


struct Size {
    var width: Int
    var height: Int

    static let zero = Size(width: 0, height: 0)
    static let max = Size(width: Int.max, height: Int.max)
}

struct DesiredSize {
    var width: Int?
    var height: Int?

    init(width: Int? = nil, height: Int? = nil) {
        self.width = width
        self.height = height
    }

    init(_ size: Size) {
        self.width = size.width
        self.height = size.height
    }

    func constrain(in size: Size) -> Size {
        return Size(
            width: min(width ?? 0, size.width),
            height: min(height ?? 0, size.height)
            )
    }
}

struct Point {
    var x: Int
    var y: Int

    static let zero = Point(x: 0, y: 0)
}

struct Frame {
    var origin: Point
    var size: Size
}

enum Location {
    static func tl(x: Int = 0, y: Int = 0) -> Location { return .topLeft(Point(x: x, y: y)) }
    static func tl(_ point: Point) -> Location { return .topLeft(point) }
    static func tc(x: Int = 0, y: Int = 0) -> Location { return .topCenter(Point(x: x, y: y)) }
    static func tc(_ point: Point) -> Location { return .topCenter(point) }
    static func tr(x: Int = 0, y: Int = 0) -> Location { return .topRight(Point(x: x, y: y)) }
    static func tr(_ point: Point) -> Location { return .topRight(point) }
    static func ml(x: Int = 0, y: Int = 0) -> Location { return .middleLeft(Point(x: x, y: y)) }
    static func ml(_ point: Point) -> Location { return .middleLeft(point) }
    static func mc(x: Int = 0, y: Int = 0) -> Location { return .middleCenter(Point(x: x, y: y)) }
    static func mc(_ point: Point) -> Location { return .middleCenter(point) }
    static func mr(x: Int = 0, y: Int = 0) -> Location { return .middleRight(Point(x: x, y: y)) }
    static func mr(_ point: Point) -> Location { return .middleRight(point) }
    static func bl(x: Int = 0, y: Int = 0) -> Location { return .bottomLeft(Point(x: x, y: y)) }
    static func bl(_ point: Point) -> Location { return .bottomLeft(point) }
    static func bc(x: Int = 0, y: Int = 0) -> Location { return .bottomCenter(Point(x: x, y: y)) }
    static func bc(_ point: Point) -> Location { return .bottomCenter(point) }
    static func br(x: Int = 0, y: Int = 0) -> Location { return .bottomRight(Point(x: x, y: y)) }
    static func br(_ point: Point) -> Location { return .bottomRight(point) }

    case none
    case topLeft(Point)
    case topCenter(Point)
    case topRight(Point)
    case middleLeft(Point)
    case middleCenter(Point)
    case middleRight(Point)
    case bottomLeft(Point)
    case bottomCenter(Point)
    case bottomRight(Point)

    func origin(for mySize: Size, in screenSize: Size) -> Point {
        switch self {
        case let .topLeft(point): return point
        case let .topCenter(point): return Point(x: point.x + (screenSize.width - mySize.width) / 2, y: point.y)
        case let .topRight(point): return Point(x: point.x + screenSize.width - mySize.width, y: point.y)
        case let .middleLeft(point): return Point(x: point.x, y: point.y + (screenSize.height - mySize.height) / 2)
        case let .middleCenter(point): return Point(x: point.x + (screenSize.width - mySize.width) / 2, y: point.y + (screenSize.height - mySize.height) / 2)
        case let .middleRight(point): return Point(x: point.x + screenSize.width - mySize.width, y: point.y + (screenSize.height - mySize.height) / 2)
        case let .bottomLeft(point): return Point(x: point.x, y: point.y + screenSize.height - mySize.height)
        case let .bottomCenter(point): return Point(x: point.x + (screenSize.width - mySize.width) / 2, y: point.y + screenSize.height - mySize.height)
        case let .bottomRight(point): return Point(x: point.x + screenSize.width - mySize.width, y: point.y + screenSize.height - mySize.height)
        default:
            return Point.zero
        }
    }
}
