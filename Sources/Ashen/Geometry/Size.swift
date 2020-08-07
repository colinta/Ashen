////
///  Size.swift
//

public struct Size: Equatable {
    public let width: Int
    public let height: Int

    public static let zero = Size(width: 0, height: 0)
    public static let max = Size(width: Int.max, height: Int.max)

    public init(width: Int, height: Int) {
        self.width = Swift.max(0, width)
        self.height = Swift.max(0, height)
    }

    public var isEmpty: Bool {
        width == 0 || height == 0
    }

    public func shrink(by: Int) -> Size {
        grow(width: -by, height: -by)
    }

    public func grow(by: Int) -> Size {
        grow(width: by, height: by)
    }

    public func shrink(width: Int = 0, height: Int = 0) -> Size {
        grow(width: -width, height: -height)
    }

    public func grow(width dw: Int, height dh: Int) -> Size {
        let width: Int
        if Int.max - self.width < dw {
            width = Int.max
        } else {
            width = self.width + dw
        }

        let height: Int
        if Int.max - self.height < dh {
            height = Int.max
        } else {
            height = self.height + dh
        }

        return Size(width: width, height: height)
    }

    public static func == (lhs: Size, rhs: Size) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }
    public static func + (lhs: Size, rhs: Size) -> Size {
        Size(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    public static func - (lhs: Size, rhs: Size) -> Size {
        Size(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    public static func + (size: Size, point: Point) -> Size {
        Size(width: size.width + point.x, height: size.height + point.y)
    }
}
