////
///  LabelView.swift
//


class LabelView: ComponentView {
    let size: DesiredSize
    let lines: [[Text]]

    var linesHeight: Int { return lines.count }
    var linesWidth: Int { return lines.reduce(0) { length, line in
            return max(length, line.count)
        } }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: size.width ?? linesWidth, height: size.height ?? linesHeight)
    }

    convenience init(_ location: Location = .tl(.zero), _ size: DesiredSize = DesiredSize(), text: String) {
        self.init(location, size, text: Text(text))
    }

    init(_ location: Location = .tl(.zero), _ size: DesiredSize = DesiredSize(), text textString: Text) {
        self.size = size
        if let textStringText = textString.text {
            let text = textStringText
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")

            var line: [String] = []
            var lines: [[String]] = []
            for c in text.characters {
                if c == "\n" {
                    lines.append(line)
                    line = []
                }
                else {
                    line.append(String(c))
                }
            }
            lines.append(line)

            self.lines = lines.map {
                $0.map { Text($0, attrs: textString.attrs) }
            }
        }
        else {
            self.lines = [[textString]]
        }

        super.init()
        self.location = location
    }

    override func render(in buffer: Buffer, size: Size) {
        var yOffset = 0
        for line in lines {
            if yOffset > size.height { break }

            var xOffset = 0
            for char in line {
                if xOffset > size.width { break }
                buffer.write(char, x: xOffset, y: yOffset)
                xOffset += 1
            }
            yOffset += 1
        }
    }
}
