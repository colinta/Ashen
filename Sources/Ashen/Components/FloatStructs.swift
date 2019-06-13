////
///  FloatStructs.swift
//


struct FloatSize {
    var width: Float
    var height: Float

    static let zero = FloatSize(width: 0, height: 0)

    init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }

    init(_ size: Size) {
        self.width = Float(size.width)
        self.height = Float(size.height)
    }

}

struct FloatPoint {
    var x: Float
    var y: Float

    var round: Point {
        return Point(
            x: Int(0.5 + x),
            y: Int(0.5 + y)
            )
    }

    static let zero = FloatPoint(x: 0, y: 0)

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

struct FloatFrame {
    var origin: FloatPoint
    var size: FloatSize

    init(x: Float, y: Float, width: Float, height: Float) {
        self.init(origin: FloatPoint(x: x, y: y), size: FloatSize(width: width, height: height))
    }

    init(origin: FloatPoint, size: FloatSize) {
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

    var minX: Float { return min(origin.x, origin.x + size.width) }
    var maxX: Float { return max(origin.x, origin.x + size.width) }
    var minY: Float { return min(origin.y, origin.y + size.height) }
    var maxY: Float { return max(origin.y, origin.y + size.height) }
    var width: Float { return max(size.width, -size.width) }
    var height: Float { return max(size.height, -size.height) }
}
