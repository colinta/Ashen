////
///  Point.swift
//

public struct Point: Equatable {
    public let x: Int
    public let y: Int

    public static let zero = Point(x: 0, y: 0)
    public static let one = Point(x: 1, y: 1)

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public static func == (lhs: Point, rhs: Point) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
    public static func + (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    public static func - (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    public static prefix func - (pt: Point) -> Point {
        Point(x: -pt.x, y: -pt.y)
    }
    public static func + (point: Point, size: Size) -> Point {
        Point(x: point.x + size.width, y: point.y + size.height)
    }
}
