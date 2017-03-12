////
///  Chars.swift
//

class Buffer {
    typealias Chars = [Int: [Int: TextType]]
    private(set) var chars: Chars = [:]
    private var offset: Point = .zero
    private var size: Size

    init(size: Size) {
        self.size = size
    }

    func push(offset nextOffset: Point, clip nextSize: Size, _ block: () -> Void) {
        guard nextSize.width > 0 && nextSize.height > 0 else { return }

        let prevOffset = offset
        let prevSize = size
        offset = Point(
            x: offset.x + nextOffset.x,
            y: offset.y + nextOffset.y
            )
        size = nextSize
        block()
        offset = prevOffset
        size = prevSize
    }

    func write(_ text: TextType, x localX: Int, y localY: Int) {
        guard
            localX >= 0 && localY >= 0 &&
            localX < size.width && localY < size.height
        else { return }

        let x = localX + offset.x
        let y = localY + offset.y
        var row = chars[y] ?? [:]
        if let prevText = row[x] {
            if prevText.text == nil, text.text != nil {
                row[x] = Text(text.text, attrs: prevText.attrs)
            }
        }
        else {
            row[x] = text
        }
        chars[y] = row
    }
}
