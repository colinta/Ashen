////
///  Buffer.swift
//

public protocol BufferKey {
    var bufferKey: String { get }
}

public class Buffer {
    public typealias Mask = [Int: [Int: Bool]]
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

                if c.character == AttributedCharacter.null.character {
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
            if !renderRow.isEmpty {
                diffedChars[y] = renderRow
            }
        }

        // overwrite removed characters with ' '
        for (y, diffRow) in diff {
            var renderRow: Row = diffedChars[y] ?? [:]
            for (x, _) in diffRow {
                if chars[y]?[x] == nil {
                    renderRow[x] = AttributedCharacter.null
                }
            }

            if !renderRow.isEmpty {
                diffedChars[y] = renderRow
            }
        }

        return diffedChars
    }

    private var chars: Chars = [:]
    public var mask: Mask {
        let initial = currentOrigin
        let maxPt = currentOrigin + currentMask.size
        var mask: Mask = [:]
        for y in initial.y..<maxPt.y {
            var row: [Int: Bool] = [:]
            for x in initial.x..<maxPt.x {
                guard
                    chars[y]?[x] == nil
                        || chars[y]?[x]?.character == AttributedCharacter.null.character
                else { continue }
                row[x] = true
            }
            mask[y] = row
        }
        return mask
    }

    // writing at local point "0, 0" writes at this offset
    private var currentOrigin: Point = .zero
    // as the screen is clipped, the offset can be moved *outside* the current clipped area.  The
    // currentMask.origin refers to the point in which drawing is "safe"
    private var currentMask: Rect
    // the "model key", which stores and retrieves view models
    private var currentKey: String = ""
    private var models: [String: Any]
    private var mouse: [Int: [Int: [MouseEvent.Button: String]]]
    private var diff: Chars?

    init(size: Size, prev: Buffer?) {
        self.currentMask = Rect(origin: .zero, size: size)
        self.models = prev?.models ?? [:]
        self.mouse = [:]
        self.diff = prev?.chars
    }

    public func push(viewport: Viewport, _ block: () -> Void) {
        // this method used to guard against renders outside the clipping area,
        // but that prevented events like `OnResize` from being called, so now
        // the clipping guard is only in `write`. Reduces the clipping logic
        // footprint, too, which is a win.

        let prevOrigin = currentOrigin
        let prevMask = currentMask
        let nextMask = Rect(origin: currentOrigin + viewport.visible.origin, size: viewport.visible.size)
        currentMask = currentMask.intersection(with: nextMask)
        currentOrigin = currentOrigin + viewport.frame.origin

        block()

        currentOrigin = prevOrigin
        currentMask = prevMask
    }

    public func render<Msg>(
        key nextKey: BufferKey,
        view: View<Msg>,
        viewport: Viewport
    ) {
        let prevKey = currentKey
        currentKey = calculateNextKey(view: view, nextKey: nextKey)
        push(viewport: viewport) {
            view.render(viewport.toLocalViewport(), self)
        }
        currentKey = prevKey
    }

    func claimMouse<Msg>(key nextKey: BufferKey, rect: Rect, mask: Mask, buttons: [MouseEvent.Button], view: View<Msg>) {
        guard buttons.count > 0 else { return }
        let currentKey = calculateNextKey(view: view, nextKey: nextKey)
        let initial = rect.origin + currentOrigin
        let maxPt = currentOrigin + currentMask.size
        guard
            initial.x + rect.width > currentMask.origin.x,
            initial.y + rect.height > currentMask.origin.y,
            initial.x < maxPt.x, initial.y < maxPt.y
        else { return }

        for y in (initial.y..<initial.y + rect.height) {
            if y > maxPt.y { break }
            guard y >= currentMask.origin.y else { continue }

            var row = mouse[y] ?? [:]
            for x in (initial.x..<initial.x + rect.width) {
                if x > maxPt.x { break }
                guard
                    x >= currentMask.origin.x,
                    mask[y]?[x] == true
                else { continue }

                var claimedEvents = row[x] ?? [:]
                for event in buttons {
                    guard claimedEvents[event] == nil else { continue }
                    claimedEvents[event] = currentKey
                }
                row[x] = claimedEvents
            }
            mouse[y] = row
        }
    }

    func checkMouse<Msg>(key nextKey: BufferKey, mouse mouseEvent: MouseEvent, view: View<Msg>) -> Bool {
        guard let row = self.mouse[mouseEvent.y], let claimedEvents = row[mouseEvent.x] else { return false }
        let currentKey = calculateNextKey(view: view, nextKey: nextKey)
        let claimedEventKey = claimedEvents[mouseEvent.button]
        return claimedEventKey == currentKey
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

    func write(_ content: Attributed, at localPt: Point) {
        let width = content.maxWidth
        let height = content.countLines
        let initial = localPt + currentOrigin
        let maxPt = currentMask.origin + currentMask.size
        guard
            initial.x + width > currentMask.origin.x, initial.y + height > currentMask.origin.y,
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
            } else if y >= currentMask.origin.y {
                let width = Buffer.displayWidth(of: ac.character)

                if x >= currentMask.origin.x, x < maxPt.x {
                    var didWrite = false
                    if let prevC = row[x],
                        prevC.character == AttributedCharacter.null.character
                    {
                        row[x] = ac.styled(prevC.attributes)
                        didWrite = true
                    } else if row[x] == nil {
                        row[x] = ac
                        didWrite = true
                    }

                    if didWrite {
                        for d in 1..<width {
                            row[x + d] = AttributedCharacter.skip
                        }
                    }
                }
                x += width
            }
        }
        chars[y] = row
    }

    func modifyCharacter(
        at localPt: Point, mask: Mask, map modify: (AttributedCharacter) -> AttributedCharacter
    ) {
        let point = localPt + currentOrigin
        let maxPt = currentOrigin + currentMask.size
        guard
            mask[point.y]?[point.x] == true,
            point.x + 1 > currentMask.origin.x, point.y + 1 > currentMask.origin.y,
            point.x < maxPt.x, point.y < maxPt.y
        else { return }

        var row = chars[point.y] ?? [:]
        let char = row[point.x] ?? AttributedCharacter.null
        guard char != AttributedCharacter.skip else { return }
        row[point.x] = modify(char)
        chars[point.y] = row
    }

    func modifyCharacters(
        in localRect: Rect, mask: Mask,
        map modify: (Int, Int, AttributedCharacter) -> AttributedCharacter
    ) {
        let initial = localRect.origin + currentOrigin
        let maxPt = currentOrigin + currentMask.size
        guard
            initial.x + localRect.width > currentMask.origin.x,
            initial.y + localRect.height > currentMask.origin.y,
            initial.x < maxPt.x, initial.y < maxPt.y
        else { return }
        for y in initial.y..<initial.y + localRect.height {
            guard y >= currentMask.origin.y else { continue }
            guard y < maxPt.y else { break }
            for x in initial.x..<initial.x + localRect.width {
                guard x >= currentMask.origin.x else { continue }
                guard x < maxPt.x else { break }

                var row = chars[y] ?? [:]
                let char = row[x] ?? AttributedCharacter.null
                guard
                    mask[y]?[x] == true,
                    char != AttributedCharacter.skip
                else { continue }
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

    static func displayWidth(of char: Character) -> Int {
        guard
            char.unicodeScalars.count == 1,
            let val = char.unicodeScalars.first?.value,
            val >= 0x1100
                && (val <= 0x115f || val == 0x2329 || val == 0x232a
                    || (val >= 0x2e80 && val <= 0xa4cf && val != 0x303f)
                    || (val >= 0xac00 && val <= 0xd7a3)
                    || (val >= 0xf900 && val <= 0xfaff)
                    || (val >= 0xfe30 && val <= 0xfe6f)
                    || (val >= 0xff00 && val <= 0xff60)
                    || (val >= 0xffe0 && val <= 0xffe6)
                    || (val >= 0x1f004 && val <= 0x1fad6)
                    || (val >= 0x20000 && val <= 0x2fffd)
                    || (val >= 0x30000 && val <= 0x3fffd))
        else {
            return 1
        }
        return 2
    }
}

extension Buffer: CustomStringConvertible {
    public var description: String {
        "currentKey: \(currentKey)\n\(Buffer.desc(chars))"
    }
}

extension String: BufferKey {
    public var bufferKey: String { return ".\(self)" }
}

extension Int: BufferKey {
    public var bufferKey: String { return "[\(self)]" }
}
