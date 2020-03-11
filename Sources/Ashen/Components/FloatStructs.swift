////
///  FloatStructs.swift
//


public struct FloatSize {
    public var width: Float
    public var height: Float

    public static let zero = FloatSize(width: 0, height: 0)

    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }

    public init(_ size: Size) {
        self.width = Float(size.width)
        self.height = Float(size.height)
    }

}

public struct FloatPoint {
    public var x: Float
    public var y: Float

    public var round: Point {
        return Point(
            x: Int(0.5 + x),
            y: Int(0.5 + y)
        )
    }

    public static let zero = FloatPoint(x: 0, y: 0)

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    func map(to canvasSize: FloatSize) -> FloatPoint? {
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return nil }

        return FloatPoint(
            x: Float(canvasSize.width - 1) * x,
            y: Float(canvasSize.height - 1) * y
        )
    }

    func map(to pixelSize: Size) -> Point? {
        guard pixelSize.width > 0 && pixelSize.height > 0 else { return nil }

        return Point(
            x: Int(0.5 + Float(pixelSize.width - 1) * x),
            y: Int(0.5 + Float(pixelSize.height - 1) * y)
        )
    }
}

public struct FloatFrame {
    public var origin: FloatPoint
    public var size: FloatSize

    public init(x: Float, y: Float, width: Float, height: Float) {
        self.init(origin: FloatPoint(x: x, y: y), size: FloatSize(width: width, height: height))
    }

    public init(origin: FloatPoint, size: FloatSize) {
        self.origin = origin
        self.size = size
    }

    func normalize(_ point: FloatPoint) -> FloatPoint? {
        guard size.width != 0 && size.height != 0 else { return nil }
        return FloatPoint(
            x: (point.x - origin.x) / size.width,
            y: 1 - (point.y - origin.y) / size.height
        )
    }

    func normalize(_ point: FloatPoint, in pixelSize: Size) -> Point? {
        return normalize(point)?.map(to: pixelSize)
    }

    public var minX: Float { return min(origin.x, origin.x + size.width) }
    public var maxX: Float { return max(origin.x, origin.x + size.width) }
    public var minY: Float { return min(origin.y, origin.y + size.height) }
    public var maxY: Float { return max(origin.y, origin.y + size.height) }
    public var width: Float { return max(size.width, -size.width) }
    public var height: Float { return max(size.height, -size.height) }
}
