////
///  Chars.swift
//

public class Buffer {
    typealias Chars = [Int: [Int: AttrCharType]]
    private(set) var chars: Chars = [:]
    private var offset: Point = .zero
    private var zeroOffset: Point = .zero
    private var size: Size

    init(size: Size) {
        self.size = size
    }

    func push(offset nextOffset: Point, clip nextDesiredSize: Size, _ block: () -> Void) {
        guard nextOffset.x < size.width, nextOffset.y < size.height else { return }
        let nextSize = Size(width: min(size.width - nextOffset.x, nextDesiredSize.width), height: min(size.height - nextOffset.y, nextDesiredSize.height))
        guard nextOffset.x + nextSize.width >= 0, nextOffset.y + nextSize.height >= 0 else { return }
        guard nextSize.width > 0, nextSize.height > 0 else { return }

        let prevOffset = offset
        let prevZeroOffset = zeroOffset
        let prevSize = size
        offset = Point(
            x: offset.x + nextOffset.x,
            y: offset.y + nextOffset.y
            )
        zeroOffset = Point(
            x: max(zeroOffset.x, offset.x),
            y: max(zeroOffset.y, offset.y)
            )
        size = nextSize
        block()
        offset = prevOffset
        zeroOffset = prevZeroOffset
        size = prevSize
    }

    func write(_ char: AttrCharType, x localX: Int, y localY: Int) {
        guard
            char.string != "",
            localX >= 0, localY >= 0,
            localX < size.width, localY < size.height
        else { return }

        let x = localX + offset.x
        let y = localY + offset.y
        guard
            x >= 0, y >= 0, x >= zeroOffset.x, y >= zeroOffset.y
        else { return }

        var row = chars[y] ?? [:]
        if let prevText = row[x] {
            if prevText.string == nil, let string = char.string {
                row[x] = AttrChar(string, prevText.attrs)
            }
        }
        else {
            row[x] = char
        }
        chars[y] = row
    }
}

extension Buffer: CustomStringConvertible {
    public var description: String {
        var description = ""
        for j in 0 ..< size.height {
            for i in 0 ..< size.width {
                guard let c = (chars[j] ?? [:])[i]
                else {
                    description += " "
                    continue
                }
                description += c.string ?? " "
            }
            description += "\n"
        }
        return description
    }
}
