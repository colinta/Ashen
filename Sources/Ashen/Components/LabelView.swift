////
///  LabelView.swift
//


public class LabelView: ComponentView, CustomDebugStringConvertible {
    let size: DesiredSize
    let chars: [AttrCharType]

    let linesHeight: Int
    let linesWidth: Int

    public var debugDescription: String {
        return "LabelView(\(chars))"
    }

    public init(_ location: Location = .tl(.zero), _ size: DesiredSize = DesiredSize(), text: TextType) {
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

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: size.width ?? linesWidth, height: size.height ?? linesHeight)
    }

    override func render(to buffer: Buffer, in rect: Rect) {
        var yOffset = 0, xOffset = 0
        for attrChar in chars {
            if attrChar.string == "\n" {
                yOffset += 1
                xOffset = 0
            }
            // y is past bottom of rect, early exit
            else if yOffset - rect.origin.y >= rect.size.height {
                break
            }
            // not yet at y=0, or x is past end of rect, skip drawing
            else if yOffset - rect.origin.y < 0 || xOffset - rect.origin.x >= rect.size.width {
                continue
            }
            // not yet at x=0, incease xOffset
            else if xOffset - rect.origin.x < 0 {
                xOffset += 1
            }
            else {
                buffer.write(attrChar, x: xOffset, y: yOffset)
                xOffset += 1
            }
        }
    }
}


extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: LabelView) {
        appendInterpolation(value.debugDescription)
    }
}
