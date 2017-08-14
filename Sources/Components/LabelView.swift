////
///  LabelView.swift
//


class LabelView: ComponentView {
    let size: DesiredSize
    let chars: [AttrCharType]

    let linesHeight: Int
    let linesWidth: Int

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: size.width ?? linesWidth, height: size.height ?? linesHeight)
    }

    init(_ location: Location = .tl(.zero), _ size: DesiredSize = DesiredSize(), text: TextType) {
        self.size = size

        let chars = text.chars
        self.chars = chars

        var linesHeight = 1
        var linesWidth = 0
        var currentWidth = 0
        for attrChar in chars {
            if attrChar.string == "\n" {
                linesHeight += 1
                linesWidth = max(linesWidth, currentWidth)
                currentWidth = 0
            }
            else {
                currentWidth += 1
            }
        }
        self.linesHeight = linesHeight
        self.linesWidth = max(linesWidth, currentWidth)

        super.init()
        self.location = location
    }

    override func render(in buffer: Buffer, size: Size) {
        var yOffset = 0, xOffset = 0
        for attrChar in chars {
            if attrChar.string == "\n" {
                yOffset += 1
                xOffset = 0
            }
            else {
                if xOffset > size.width { continue }
                buffer.write(attrChar, x: xOffset, y: yOffset)
                xOffset += 1
            }
        }
    }
}
