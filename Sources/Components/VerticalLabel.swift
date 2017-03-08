////
///  VerticalLabelView.swift
//


class VerticalLabelView: ComponentView {
    let size: DesiredSize
    let line: [Text]

    var linesWidth: Int { return 1 }
    var linesHeight: Int { return line.count }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: linesWidth, height: size.height ?? linesHeight)
    }

    convenience init(_ location: Location, _ height: Float? = nil, text: String) {
        self.init(location, height, text: Text(text))
    }

    init(_ location: Location, _ height: Float? = nil, text textString: Text) {
        self.size = DesiredSize(width: 1, height: height)
        self.line = line.map {
            Text(String($0), attrs: textString.attrs)
        }
        super.init()
        self.location = location
    }

    override func render(in buffer: Buffer, size: Size) {
        var yOffset = 0
        for char in line {
            if yOffset > size.height { return memo }
            buffer.write(char, x: 0, y: yOffset)
        }
    }
}
