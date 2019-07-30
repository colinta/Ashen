////
///  CanvasView.swift
//

private let BRAILLE_START = 0x2800

public class CanvasView: ComponentView {
    public enum Drawable {
        case line(FloatPoint, FloatPoint)
        case box(FloatPoint, FloatSize)
        case fn((Float) -> Float)
        case absBox(Point, Size)
        case offsetBox(Int)
        case border

        func draw(in canvas: PixelCanvas, viewport: FloatFrame, pixelSize: Size) {
            switch self {
            case let .fn(function):
                drawFunction(in: canvas, function, viewport: viewport, pixelSize: pixelSize)
            case let .line(p0, p1):
                drawLine(in: canvas, p0, p1, viewport: viewport, pixelSize: pixelSize)
            case let .box(origin, size):
                drawBox(in: canvas, origin, size, viewport: viewport, pixelSize: pixelSize)
            case let .absBox(origin, size):
                drawAbsBox(in: canvas, origin, size)
            case let .offsetBox(margin):
                let size = Size(width: pixelSize.width - 2 * margin - 1, height: pixelSize.height - 2 * margin - 1)
                guard size.width > 0, size.height > 0 else { return }

                let origin = Point(x: margin, y: margin)
                drawAbsBox(in: canvas, origin, size)
            case .border:
                Drawable.offsetBox(0).draw(in: canvas, viewport: viewport, pixelSize: pixelSize)
            }
        }

        private func drawFunction(in canvas: PixelCanvas, _ function: (Float) -> Float, viewport: FloatFrame, pixelSize: Size) {
            let x0 = viewport.minX
            let x1 = viewport.maxX
            let dx = viewport.width / Float(pixelSize.width - 1)
            var x: Float = x0
            while x <= x1 {
                let y = function(x)
                let p = FloatPoint(x: x, y: y)
                if let np = viewport.normalize(p, in: pixelSize) {
                    canvas.on(np)
                }
                x += dx
            }
        }

        private func drawLine(in canvas: PixelCanvas, _ a: FloatPoint, _ b: FloatPoint, viewport: FloatFrame, pixelSize: Size) {
            guard
                let pa: FloatPoint = viewport.normalize(a)?.map(to: FloatSize(pixelSize)),
                let pb: FloatPoint = viewport.normalize(b)?.map(to: FloatSize(pixelSize))
            else { return }

            let width = abs(pb.x - pa.x)
            let height = abs(pb.y - pa.y)
            let dx: Float = pa.x < pb.x ? 1 : -1
            let dy: Float = pa.y < pb.y ? 1 : -1

            var pt = pa
            canvas.on(pt.round)
            guard width > 0 || height > 0 else { return }

            if width > height {
                while true {
                    pt.x += dx
                    if abs(pt.x - pa.x) > width { break }
                    canvas.on(pt.round)

                    let desiredY = pa.y + (pt.x - pa.x) * (pb.y - pa.y) / (pb.x - pa.x)
                    while abs(desiredY - pt.y) > 0.5 {
                        canvas.on(pt.round)
                        pt.y += dy
                    }
                }
            }
            else {
                while true {
                    pt.y += dy
                    if abs(pt.y - pa.y) > height { break }
                    canvas.on(pt.round)

                    let desiredX = pa.x + (pt.y - pa.y) * (pb.x - pa.x) / (pb.y - pa.y)
                    while abs(desiredX - pt.x) > 0.5 {
                        canvas.on(pt.round)
                        pt.x += dx
                    }
                }
            }
        }

        private func drawBox(in canvas: PixelCanvas, _ origin: FloatPoint, _ size: FloatSize, viewport: FloatFrame, pixelSize: Size) {
            guard size.width > 0 && size.height > 0 else { return }

            guard
                let p0: Point = viewport.normalize(origin, in: pixelSize),
                let p1: Point = viewport.normalize(FloatPoint(x: origin.x + size.width, y: origin.y + size.height), in: pixelSize)
            else { return }

            return drawAbsBox(in: canvas, Point(x: p0.x, y: p0.y), Size(width: p1.x - p0.x, height: p1.y - p0.y))
        }

        private func drawAbsBox(in canvas: PixelCanvas, _ origin: Point, _ size: Size) {
            let (x0, y0) = (min(origin.x, origin.x + size.width), min(origin.y, origin.y + size.height))
            let (x1, y1) = (max(origin.x, origin.x + size.width), max(origin.y, origin.y + size.height))

            if size.height > 0 {
                for y in y0 ... y1 {
                    canvas.on(Point(x: x0, y: y))
                    canvas.on(Point(x: x1, y: y))
                }
            }

            if size.width > 2 {
                for x in (x0 + 1) ... (x1 - 1) {
                    canvas.on(Point(x: x, y: y0))
                    canvas.on(Point(x: x, y: y1))
                }
            }
        }
    }

    class PixelCanvas {
        private var points: [Int: [Int: Bool]] = [:]
        private var maxX = 0, maxY = 0

        func on(_ pt: Point) {
            var row = points[pt.y] ?? [:]
            row[pt.x] = true
            points[pt.y] = row
            maxX = max(maxX, pt.x)
            maxY = max(maxY, pt.y)
        }

        func status(_ x: Int, _ y: Int) -> Int {
            guard
                let row = points[y],
                let on = row[x]
            else { return 0 }
            return on ? 1 : 0
        }

        func render(to buffer: Buffer) {
            var py = 0
            let dy = 4
            var sy = 0
            let dx = 2
            while py <= maxY {
                var px = 0
                var sx = 0
                while px <= maxX {
                    let b1 = status(px, py)
                    let b2 = status(px, py + 1)
                    let b3 = status(px, py + 2)
                    let b4 = status(px + 1, py)
                    let b5 = status(px + 1, py + 1)
                    let b6 = status(px + 1, py + 2)
                    let b7 = status(px, py + 3)
                    let b8 = status(px + 1, py + 3)
                    let unicode = b1 + b2 << 1 + b3 << 2 + b4 << 3 + b5 << 4 + b6 << 5 + b7 << 6 + b8 << 7
                    if unicode > 0,
                        let char = UnicodeScalar(BRAILLE_START + unicode).map({ String(describing: $0) })
                    {
                        buffer.write(AttrChar(char), x: sx, y: sy)
                    }

                    px += dx
                    sx += 1
                }
                py += dy
                sy += 1
            }
        }
    }

    let size: DesiredSize
    let viewport: FloatFrame
    let drawables: [Drawable]

    public init(at location: Location = .tl(.zero), size: DesiredSize, viewport: FloatFrame, drawables: [Drawable]) {
        self.size = size
        self.viewport = viewport
        self.drawables = drawables
        super.init()
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return size
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        let drawSize = Size(
            width: rect.size.width * 2, // braille characters are 2 columns
            height: rect.size.height * 4 // and 4 rows
            )
        let canvas = PixelCanvas()
        for drawable in drawables {
            drawable.draw(in: canvas, viewport: viewport, pixelSize: drawSize)
        }
        canvas.render(to: buffer)
    }
}
