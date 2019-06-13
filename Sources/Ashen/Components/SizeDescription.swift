////
///  SideDescription.swift
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
