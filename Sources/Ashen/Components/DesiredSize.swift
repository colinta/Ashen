////
///  DesiredSize.swift
//

public struct DesiredSize {
    public var width: Dimension?
    public var height: Dimension?

    static public let zero = DesiredSize(width: 0, height: 0)
    static public let max = DesiredSize(width: .max, height: .max)

    public init(calculate: @escaping (Size) -> Size) {
        self.width = .calculate({ size in calculate(size).width })
        self.height = .calculate({ size in calculate(size).height })
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
        let width = constrain(self.width, in: size, max: size.width)
        let height = constrain(self.height, in: size, max: size.height)
        return Size(width: width, height: height)
    }

    private func constrain(_ dimension: Dimension?, in size: Size, max: Int) -> Int {
        guard let dimension = dimension else { return 0 }

        switch dimension {
        case let .literal(literal):
            return literal
        case let .calculate(calculate):
            return calculate(size)
        case .max:
            return max
        case let .smallest(values):
            return values.filter({ $0 <= max }).min() ?? 0
        case let .biggest(values):
            return values.filter({ $0 <= max }).max() ?? 0
        }
    }
}

public enum Dimension {
    case literal(Int)
    case calculate((Size) -> Int)
    case max
    case smallest([Int])
    case biggest([Int])
}

extension Dimension: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .literal(integerLiteral)
    }
}
