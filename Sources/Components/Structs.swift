////
///  Structs.swift
//


struct SizeDescription {
    var multiplier: FloatSize
    var offset: Size

    func calcSize(in parentSize: Size) -> Size {
        return Size(
            width: Int(multiplier.width * Float(parentSize.width) + 0.5) + offset.width,
            height: Int(multiplier.height * Float(parentSize.height) + 0.5) + offset.height
            )
    }

    static func size(width: Int = 1, height: Int = 1) -> SizeDescription {
        return SizeDescription(multiplier: FloatSize.zero, offset: Size(width: width, height: height))
    }

    static func width(_ width: Int) -> SizeDescription {
        return SizeDescription(multiplier: FloatSize.zero, offset: Size(width: width, height: 1))
    }
    func width(_ width: Int) -> SizeDescription {
        return SizeDescription(multiplier: FloatSize.zero, offset: Size(width: width, height: offset.height))
    }

    static func width(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: times * percent / 100, height: 0),
            offset: Size(width: plus - minus, height: 1))
    }
    func width(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: times * percent / 100, height: multiplier.height),
            offset: Size(width: plus - minus, height: offset.height))
    }

    static func height(_ height: Int) -> SizeDescription {
        return SizeDescription(multiplier: FloatSize.zero, offset: Size(width: 1, height: height))
    }
    func height(_ height: Int) -> SizeDescription {
        return SizeDescription(multiplier: FloatSize.zero, offset: Size(width: offset.width, height: height))
    }

    static func height(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 0, height: times * percent / 100),
            offset: Size(width: 1, height: plus - minus))
    }
    func height(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: multiplier.width, height: times * percent / 100),
            offset: Size(width: offset.width, height: plus - minus))
    }

    static func minus(_ margin: Int) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: -margin, height: -margin))
    }
    static func minus(width: Int = 0, height: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: -width, height: -height))
    }
    func minus(_ margin: Int) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width - margin, height: offset.height - margin))
    }
    func minus(width: Int = 0, height: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width - width, height: offset.height - height))
    }

    static func plus(_ margin: Int) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: margin, height: margin))
    }
    static func plus(width: Int = 0, height: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: width, height: height))
    }
    func plus(_ margin: Int) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width + margin, height: offset.height + margin))
    }
    func plus(width: Int = 0, height: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width + width, height: offset.height + height))
    }

    static func fullWidth(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: 0),
            offset: Size(width: plus - minus, height: 1)
            )
    }
    func fullWidth(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 1, height: multiplier.height),
            offset: Size(width: plus - minus, height: offset.height)
            )
    }

    static func fullHeight(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: 0, height: 1),
            offset: Size(width: 1, height: plus - minus)
            )
    }
    func fullHeight(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        return SizeDescription(
            multiplier: FloatSize(width: multiplier.width, height: 1),
            offset: Size(width: offset.width, height: plus - minus)
            )
    }
}

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
    static func at(x: Int = 0, y: Int = 0) -> Location { return .tl(Point(x: x, y: y)) }
    static func at(_ point: Point) -> Location { return .tl(point) }
    static func topLeft(x: Int = 0, y: Int = 0) -> Location { return .tl(Point(x: x, y: y)) }
    static func topLeft(_ point: Point) -> Location { return .tl(point) }
    static func topCenter(x: Int = 0, y: Int = 0) -> Location { return .tc(Point(x: x, y: y)) }
    static func topCenter(_ point: Point) -> Location { return .tc(point) }
    static func topRight(x: Int = 0, y: Int = 0) -> Location { return .tr(Point(x: x, y: y)) }
    static func topRight(_ point: Point) -> Location { return .tr(point) }
    static func middleLeft(x: Int = 0, y: Int = 0) -> Location { return .ml(Point(x: x, y: y)) }
    static func middleLeft(_ point: Point) -> Location { return .ml(point) }
    static func middleCenter(x: Int = 0, y: Int = 0) -> Location { return .mc(Point(x: x, y: y)) }
    static func middleCenter(_ point: Point) -> Location { return .mc(point) }
    static func middleRight(x: Int = 0, y: Int = 0) -> Location { return .mr(Point(x: x, y: y)) }
    static func middleRight(_ point: Point) -> Location { return .mr(point) }
    static func bottomLeft(x: Int = 0, y: Int = 0) -> Location { return .bl(Point(x: x, y: y)) }
    static func bottomLeft(_ point: Point) -> Location { return .bl(point) }
    static func bottomCenter(x: Int = 0, y: Int = 0) -> Location { return .bc(Point(x: x, y: y)) }
    static func bottomCenter(_ point: Point) -> Location { return .bc(point) }
    static func bottomRight(x: Int = 0, y: Int = 0) -> Location { return .br(Point(x: x, y: y)) }
    static func bottomRight(_ point: Point) -> Location { return .br(point) }

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
