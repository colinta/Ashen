////
///  Buffer.swift
//

protocol BufferKey {
    var bufferKey: String { get }
}

public class Buffer {
    public typealias Row = [Int: AttributedCharacter]
    public typealias Chars = [Int: Row]

    public static func desc(_ chars: Chars) -> String {
        var description = ""
        let height = chars.reduce(0) { m0, kv0 in
            max(m0, kv0.key)
        }
        let width = chars.reduce(0) { memo, kv in
            max(
                memo,
                kv.value.reduce(0) { m1, kv1 in
                    max(m1, kv1.key)
                })
        }
        for y in 0...height {
            guard let row = chars[y] else {
                description += "↩︎\n"
                continue
            }

            for x in 0...width {
                guard let c = row[x] else {
                    description += "."
                    continue
                }

                if c.character == "\u{0}" {
                    description += String("◦")
                } else {
                    description += String(c.character)
                }
            }

            description += "↩︎\n"
        }
        return description
    }

    var diffedChars: Chars {
        guard let diff = diff else { return chars }

        var diffedChars: Chars = [:]
        // assign new characters
        for (y, row) in chars {
            guard let diffRow = diff[y] else {
                diffedChars[y] = row
                continue
            }

            var renderRow: Row = [:]
            for (x, c) in row {
                guard let diffC = diffRow[x] else {
                    renderRow[x] = c
                    continue
                }

                if diffC != c {
                    renderRow[x] = c
                }
            }
            diffedChars[y] = renderRow
        }

        // overwrite removed characters with ' '
        for (y, diffRow) in diff {
            var renderRow: Row = diffedChars[y] ?? [:]
            for (x, _) in diffRow {
                if chars[y]?[x] == nil {
                    renderRow[x] = AttributedCharacter(character: " ", attributes: [])
                }
            }
            diffedChars[y] = renderRow
        }

        return diffedChars
    }

    var chars: Chars = [:]

    // writing at local point "0, 0" writes at this offset
    private var currentOffset: Point = .zero
    // as the screen is clipped, the offset can be moved *outside* the current clipped area.  The
    // zeroOrigin refers to the point where drawing is "safe"
    private var zeroOrigin: Point = .zero
    // the clipped size, measured from the offset
    private var currentClipSize: Size
    // the "model key", which stores and retrieves view models
    private var currentKey: String = ""
    private var models: [String: Any]
    private var mouse: [Int: [Int: String]]
    private var diff: Chars?

    init(size: Size, prev: Buffer?) {
        self.currentClipSize = size
        self.models = prev?.models ?? [:]
        self.mouse = [:]
        self.diff = prev?.chars
    }

    func push(
        at origin: Point,
        clip nextDesiredSize: Size,
        _ block: () -> Void
    ) {
        // this method used to guard against renders outside the clipping area,
        // but that prevented events like `OnResize` from being called, so now
        // the clipping guard is only in `write`. Reduces the clipping logic
        // footprint, too, which is a win.

        let nextSize = Size(
            width: min(currentClipSize.width - origin.x, nextDesiredSize.width),
            height: min(currentClipSize.height - origin.y, nextDesiredSize.height)
        )
        let prevOffset = currentOffset
        let prevZeroOrigin = zeroOrigin
        let prevClipSize = currentClipSize

        currentOffset = currentOffset + origin
        zeroOrigin = Point(
            x: max(zeroOrigin.x, currentOffset.x),
            y: max(zeroOrigin.y, currentOffset.y)
        )
        currentClipSize = nextSize

        block()

        currentOffset = prevOffset
        zeroOrigin = prevZeroOrigin
        currentClipSize = prevClipSize
    }

    func render<Msg>(
        key nextKey: BufferKey,
        view: View<Msg>,
        at origin: Point,
        clip nextDesiredSize: Size,
        offset renderOffset: Point = .zero
    ) {
        let prevKey = currentKey
        currentKey = calculateNextKey(view: view, nextKey: nextKey)
        push(at: origin, clip: nextDesiredSize) {
            let innerRect = Rect(origin: renderOffset, size: nextDesiredSize)
            view.render(innerRect, self)

        }
        currentKey = prevKey
    }

    func claimMouse<Msg>(key nextKey: BufferKey, rect: Rect, view: View<Msg>) {
        let currentKey = calculateNextKey(view: view, nextKey: nextKey)
        let initial = rect.origin + currentOffset
        let maxPt = currentOffset + currentClipSize
        guard
            initial.x + rect.width > zeroOrigin.x, initial.y + rect.height > zeroOrigin.y,
            initial.x < maxPt.x, initial.y < maxPt.y
        else { return }

        for y in (initial.y..<initial.y + rect.height) {
            if y > maxPt.y { break }
            guard y >= zeroOrigin.y else { continue }

            var row = mouse[y] ?? [:]
            for x in (initial.x..<initial.x + rect.width) {
                if x > maxPt.x { break }
                guard
                    x >= zeroOrigin.x,
                    row[x] == nil
                else { continue }
                row[x] = currentKey
            }
            mouse[y] = row
        }
    }

    func checkMouse<Msg>(key nextKey: BufferKey, mouse: MouseEvent, view: View<Msg>) -> Bool {
        guard let row = self.mouse[mouse.y], let checkKey = row[mouse.x] else { return false }
        let currentKey = calculateNextKey(view: view, nextKey: nextKey)
        return currentKey == checkKey
    }

    func events<Msg>(key nextKey: BufferKey, event: Event, view: View<Msg>) -> ([Msg], [Event]) {
        let prevKey = currentKey
        currentKey = calculateNextKey(view: view, nextKey: nextKey)
        let events = view.events(event, self)
        currentKey = prevKey
        return events
    }

    func store(_ model: Any) {
        models[currentKey] = model
    }

    func retrieve<T>() -> T? {
        return models[currentKey] as? T

    }

    func write(_ content: Attributed, at localPt: Point, attributes extraAttributes: [Attr] = []) {
        let width = content.maxWidth
        let height = content.countLines
        let initial = localPt + currentOffset
        let maxPt = currentOffset + currentClipSize
        guard
            initial.x + width > zeroOrigin.x, initial.y + height > zeroOrigin.y,
            initial.x < maxPt.x, initial.y < maxPt.y
        else { return }

        var x = initial.x
        var y = initial.y
        var row = chars[y] ?? [:]
        for ac in content.attributedCharacters {
            if ac.character == "\n" {
                chars[y] = row

                y += 1
                if y >= maxPt.y {
                    // do not 'break' out of the loop, because the current line
                    // "buffer" is assigned to self.chars
                    return
                }

                row = chars[y] ?? [:]
                x = initial.x
            } else if y >= zeroOrigin.y {
                if x >= zeroOrigin.x, x < maxPt.x {
                    if let prevC = row[x], prevC.character == "\u{0000}" {
                        row[x] = ac.styled(prevC.attributes + extraAttributes)
                    } else if row[x] == nil {
                        row[x] = ac.styled(extraAttributes)
                    }
                }
                x += 1
            }
        }
        chars[y] = row
    }

    func modifyCharacter(
        at localPt: Point, map modify: (AttributedCharacter) -> AttributedCharacter
    ) {
        let point = localPt + currentOffset
        let maxPt = currentOffset + currentClipSize
        guard
            point.x + 1 > zeroOrigin.x, point.y + 1 > zeroOrigin.y,
            point.x < maxPt.x, point.y < maxPt.y
        else { return }
        var row = chars[point.y] ?? [:]
        let char = row[point.x] ?? AttributedCharacter(character: "\u{0000}", attributes: [])
        row[point.x] = modify(char)
        chars[point.y] = row
    }

    func modifyCharacters(
        in localRect: Rect, map modify: (Int, Int, AttributedCharacter) -> AttributedCharacter
    ) {
        let initial = localRect.origin + currentOffset
        let maxPt = currentOffset + currentClipSize
        guard
            initial.x + localRect.width > zeroOrigin.x, initial.y + localRect.height > zeroOrigin.y,
            initial.x < maxPt.x, initial.y < maxPt.y
        else { return }
        for y in initial.y..<initial.y + localRect.height {
            guard y >= zeroOrigin.y else { continue }
            guard y < maxPt.y else { break }
            for x in initial.x..<initial.x + localRect.width {
                guard x >= zeroOrigin.x else { continue }
                guard x < maxPt.x else { break }

                var row = chars[y] ?? [:]
                let char = row[x] ?? AttributedCharacter(character: "\u{0000}", attributes: [])
                row[x] = modify(x, y, char)
                chars[y] = row
            }
        }
    }

    func calculateNextKey<Msg>(view: View<Msg>, nextKey: BufferKey) -> String {
        if let id = view.id {
            return "#\(id)"
        } else if let overrideKey = view.key {
            return "\(currentKey){\(overrideKey)}"
        } else {
            return currentKey + nextKey.bufferKey
        }
    }
}

extension Buffer: CustomStringConvertible {
    public var description: String {
        "currentKey: \(currentKey)\n\(Buffer.desc(chars))"
    }
}

extension String: BufferKey {
    var bufferKey: String { return ".\(self)" }
}

extension Int: BufferKey {
    var bufferKey: String { return "[\(self)]" }
}
