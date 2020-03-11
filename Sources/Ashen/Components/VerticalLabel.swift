////
///  VerticalLabelView.swift
//


public class VerticalLabelView: ComponentView {
    let height: Dimension
    let chars: [AttrCharType]

    var linesHeight: Int { chars.count }

    public init(at location: Location = .tl(.zero), _ height: Dimension = .max, text: TextType) {
        self.height = height
        self.chars = text.chars

        super.init()
        self.location = location
    }

    override public func desiredSize() -> DesiredSize {
        DesiredSize(width: 1, height: height)
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        guard rect.origin.x == 0 else { return }

        var yOffset = 0
        for attrChar in chars {
            if yOffset > rect.size.height { return }
            if yOffset >= rect.origin.y {
                buffer.write(attrChar, x: 0, y: yOffset)
            }
            yOffset += 1
        }
    }
}
