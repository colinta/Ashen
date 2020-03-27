////
///  DesiredSize.swift
//

public struct DesiredSize {
    public var width: Dimension?
    public var height: Dimension?

    static public let zero = DesiredSize(width: 0, height: 0)
    static public let max = DesiredSize(width: .max, height: .max)

    public init(calculate: @escaping (Size) -> Size) {
        self.width = .calculate({ size, _ in calculate(size).width })
        self.height = .calculate({ size, _ in calculate(size).height })
    }

    public init(width: Dimension? = nil, height: Dimension? = nil) {
        self.width = width
        self.height = height
    }

    public init(width: Int, height: Int) {
        self.width = .literal(width)
        self.height = .literal(height)
    }

    public init(width: Int) {
        self.width = .literal(width)
        self.height = nil
    }

    public init(height: Int) {
        self.width = nil
        self.height = .literal(height)
    }

    public init(_ size: Size) {
        self.width = .literal(size.width)
        self.height = .literal(size.height)
    }

    func constrain(in size: Size) -> Size {
        let width = self.width?.constrain(in: size, axis: .x) ?? 0
        let height = self.height?.constrain(in: size, axis: .y) ?? 0
        return Size(width: width, height: height)
    }
}

public enum Axis {
    case x
    case y
}

public enum Dimension {
    case literal(Int)
    case percent(Int)
    case max
    case biggest(of: [Int])
    case calculate((Size, Axis) -> Int)

    func plus(_ delta: Int) -> Dimension {
        let dimension = self
        return .calculate { size, axis in
            return dimension.constrain(in: size, axis: axis) + delta
        }
    }

    func minus(_ delta: Int) -> Dimension {
        plus(-delta)
    }

    func constrain(in size: Size, axis: Axis) -> Int {
        let max: Int
        switch axis {
        case .x: max = size.width
        case .y: max = size.height
        }

        switch self {
        case let .literal(literal):
            return literal
        case let .calculate(calculate):
            return calculate(size, axis)
        case .max:
            return max
        case let .percent(percent):
            return max * percent / 100
        case let .biggest(values):
            return values.filter({ $0 <= max }).max() ?? 0
        }
    }

}

extension Dimension: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .literal(integerLiteral)
    }
}
