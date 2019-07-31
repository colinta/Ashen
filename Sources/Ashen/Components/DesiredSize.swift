////
///  DesiredSize.swift
//

public struct DesiredSize {
    public var width: Dimension?
    public var height: Dimension?

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
        let width = constrain(self.width, in: size.width)
        let height = constrain(self.height, in: size.height)
        return Size(width: width, height: height)
    }

    private func constrain(_ dimension: Dimension?, in size: Int) -> Int {
        switch dimension ?? .max {
        case let .literal(literal):
            return literal
        case .max:
            return size
        case let .smallest(values):
            return values.filter({ $0 < size }).min() ?? 0
        case let .biggest(values):
            return values.filter({ $0 < size }).max() ?? 0
        }
    }
}

public enum Dimension {
    case literal(Int)
    case max
    case smallest([Int])
    case biggest([Int])
}

extension Dimension: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .literal(integerLiteral)
    }
}