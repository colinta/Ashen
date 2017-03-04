////
///  VerticalLabelView.swift
//


class VerticalLabelView: ComponentViewType {
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

    override func chars(in size: Size) -> Screen.Chars {
        var yOffset = 0
        line.reduce([Int: [Int: TextType]]()) { (memo, char) in
            if yOffset > size.height { return memo }

            var next = memo
            next[yOffset] = [0: char]
            yOffset += 1
            return next
        }
    }
}
