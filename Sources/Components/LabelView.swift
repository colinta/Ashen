////
///  LabelView.swift
//


class LabelView: ComponentViewType {
    let size: DesiredSize

    let lines: [[Text]]
    var linesHeight: Int { return lines.count }
    var linesWidth: Int { return lines.reduce(0) { length, line in
            return max(length, line.count)
        } }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: size.width ?? linesWidth, height: size.height ?? linesHeight)
    }

    convenience init(_ location: Location, _ size: DesiredSize = DesiredSize(), text: String) {
        self.init(location, size, text: Text(text))
    }

    init(_ location: Location, _ size: DesiredSize = DesiredSize(), text textString: Text) {
        self.size = size
        let lines = textString.text.characters.split { $0 == "\n" }
        self.lines = lines.map {
            $0.map { Text(String($0), attrs: textString.attrs) }
        }
        super.init()
        self.location = location
    }

    override func chars(in size: Size) -> Screen.Chars {
        var yOffset = 0
        return lines.reduce(Screen.Chars()) { (memo, line) in
            if yOffset > size.height { return memo }

            var xOffset = 0
            var row = memo
            row[yOffset] = line.reduce([Int: TextType]()) { (memo, char) in
                if xOffset > size.width { return memo }

                var next = memo
                next[xOffset] = char
                xOffset += 1
                return next
            }
            yOffset += 1
            return row
        }
    }
}
