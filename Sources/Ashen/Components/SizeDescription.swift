////
///  SideDescription.swift
//


public struct SizeDescription {
    var multiplier: FloatSize
    var offset: Size

    func calcSize(in parentSize: Size) -> Size {
        Size(
            width: Int(multiplier.width * Float(parentSize.width) + 0.5) + offset.width,
            height: Int(multiplier.height * Float(parentSize.height) + 0.5) + offset.height
        )
    }

    public static func size(width: Int = 1, height: Int = 1) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize.zero,
            offset: Size(width: width, height: height)
        )
    }

    public static func width(_ width: Int) -> SizeDescription {
        SizeDescription(multiplier: FloatSize.zero, offset: Size(width: width, height: 1))
    }
    public func width(_ width: Int) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize.zero,
            offset: Size(width: width, height: offset.height)
        )
    }

    public static func width(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0)
        -> SizeDescription
    {
        SizeDescription(
            multiplier: FloatSize(width: times * percent / 100, height: 0),
            offset: Size(width: plus - minus, height: 1)
        )
    }
    public func width(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0)
        -> SizeDescription
    {
        SizeDescription(
            multiplier: FloatSize(width: times * percent / 100, height: multiplier.height),
            offset: Size(width: plus - minus, height: offset.height)
        )
    }

    public static func height(_ height: Int) -> SizeDescription {
        SizeDescription(multiplier: FloatSize.zero, offset: Size(width: 1, height: height))
    }
    public func height(_ height: Int) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize.zero,
            offset: Size(width: offset.width, height: height)
        )
    }

    public static func height(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0)
        -> SizeDescription
    {
        SizeDescription(
            multiplier: FloatSize(width: 0, height: times * percent / 100),
            offset: Size(width: 1, height: plus - minus)
        )
    }
    public func height(percent: Float = 100, times: Float = 1, plus: Int = 0, minus: Int = 0)
        -> SizeDescription
    {
        SizeDescription(
            multiplier: FloatSize(width: multiplier.width, height: times * percent / 100),
            offset: Size(width: offset.width, height: plus - minus)
        )
    }

    public static func minus(_ margin: Int) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: -margin, height: -margin)
        )
    }
    public static func minus(width: Int = 0, height: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: -width, height: -height)
        )
    }
    public func minus(_ margin: Int) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width - margin, height: offset.height - margin)
        )
    }
    public func minus(width: Int = 0, height: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width - width, height: offset.height - height)
        )
    }

    public static func plus(_ margin: Int) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: margin, height: margin)
        )
    }
    public static func plus(width: Int = 0, height: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: width, height: height)
        )
    }
    public func plus(_ margin: Int) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width + margin, height: offset.height + margin)
        )
    }
    public func plus(width: Int = 0, height: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 1),
            offset: Size(width: offset.width + width, height: offset.height + height)
        )
    }

    public static func fullWidth(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: 0),
            offset: Size(width: plus - minus, height: 1)
        )
    }
    public func fullWidth(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 1, height: multiplier.height),
            offset: Size(width: plus - minus, height: offset.height)
        )
    }

    public static func fullHeight(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: 0, height: 1),
            offset: Size(width: 1, height: plus - minus)
        )
    }
    public func fullHeight(plus: Int = 0, minus: Int = 0) -> SizeDescription {
        SizeDescription(
            multiplier: FloatSize(width: multiplier.width, height: 1),
            offset: Size(width: offset.width, height: plus - minus)
        )
    }
}
