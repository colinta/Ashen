////
///  VerticalLabelView.swift
//


public class VerticalLabelView: ComponentView {
    let size: DesiredSize
    let chars: [AttrCharType]

    var linesWidth: Int { return 1 }
    var linesHeight: Int { return chars.count }

    public init(_ location: Location, _ height: Int? = nil, text: TextType) {
        self.size = DesiredSize(width: 1, height: height)
        self.chars = text.chars

        super.init()
        self.location = location
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: linesWidth, height: size.height ?? linesHeight)
    }

    override func render(in buffer: Buffer, size: Size) {
        var yOffset = 0
        for attrChar in chars {
            if yOffset > size.height { return }
            buffer.write(attrChar, x: 0, y: yOffset)
            yOffset += 1
        }
    }
}
