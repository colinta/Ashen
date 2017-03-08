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

    func push(offset nextOffset: Point, _ block: () -> Void) {
        let prevOffset = offset
        offset = Point(
            x: offset.x + nextOffset.x,
            y: offset.y + nextOffset.y
            )
        block()
        offset = prevOffset
    }

    func write(_ text: TextType, x localX: Int, y localY: Int) {
        let x = localX + offset.x
        let y = localY + offset.y
        guard x >= 0 && y >= 0 && x < size.width && y < size.height else { return }

        var row = chars[y] ?? [:]
        row[x] = text
        chars[y] = row
    }
}
