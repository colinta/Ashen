////
///  LabelView.swift
//


class LabelView: ComponentView {
    let size: DesiredSize
    let lines: [TextType]

    var linesHeight: Int { return lines.count }
    var linesWidth: Int { return lines.reduce(0) { length, line in
            return max(length, line.chars.count)
        } }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: size.width ?? linesWidth, height: size.height ?? linesHeight)
    }

    init(_ location: Location = .tl(.zero), _ size: DesiredSize = DesiredSize(), text: TextType) {
        self.size = size

        var line = AttrText()
        var lines: [TextType] = []
        for attrChar in text.chars {
            if attrChar.string == "\n" {
                lines.append(line)
                line = AttrText()
            }
            else {
                line.append(attrChar)
            }
        }
        lines.append(line)
        self.lines = lines
        super.init()
        self.location = location
    }

    override func render(in buffer: Buffer, size: Size) {
        var yOffset = 0
        for line in lines {
            if yOffset > size.height { break }

            var xOffset = 0
            for char in line.chars {
                if xOffset > size.width { break }
                buffer.write(char, x: xOffset, y: yOffset)
                xOffset += 1
            }
            yOffset += 1
        }
    }
}
