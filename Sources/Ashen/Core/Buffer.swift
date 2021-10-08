////
///  Buffer.swift
//

public class Buffer {
    public typealias Row = [Int: AttributedCharacter]
    public typealias Chars = [Int: Row]
    public typealias Mask = Chars
    typealias ClaimedMouseEvents = (ViewKey, [MouseEvent.Button])
    typealias MouseEvents = [Int: [Int: ClaimedMouseEvents]]

    private var chars: Chars = [:]
    // the mask represents the "writable" region of the buffer
    var mask: Mask {
        let initial = currentOrigin
        let maxPt = currentOrigin + currentMask.size
        var mask: Mask = [:]
        for y in initial.y..<maxPt.y {
            var row: Row = [:]
            for x in initial.x..<maxPt.x {
                guard
                    chars[y]?[x] == nil
                        || chars[y]?[x]?.character == AttributedCharacter.null.character
                else { continue }
                row[x] = chars[y]?[x] ?? AttributedCharacter.null
            }
            mask[y] = row
        }
        return mask
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

    // writing at local point "0, 0" writes at this offset
    private var currentOrigin: Point = .zero
    // as the screen is clipped, the offset can be moved *outside* the current clipped area.  The
    // currentMask.origin refers to the point in which drawing is "safe"
    private var currentMask: Rect
    // the "model key", which stores and retrieves view models
    private var currentKey: ViewKey = .none
    private var models: [String: Any]
    private var prevModels: [String: Any]
    private var mouse: MouseEvents
    private var diff: Chars?

    public init(size: Size, prev: Buffer?) {
        self.currentMask = Rect(origin: .zero, size: size)
        self.models = [:]
        self.prevModels = prev?.models ?? [:]
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
        let nextMask = Rect(
            origin: currentOrigin + viewport.visible.origin, size: viewport.visible.size)
        currentMask = currentMask.intersection(with: nextMask)
        currentOrigin = currentOrigin + viewport.frame.origin

        block()

        currentOrigin = prevOrigin
        currentMask = prevMask
    }

    public func copy(into: Buffer, from: Rect, at dest: Point) {
        let mask = into.mask
        var text: Chars = [:]
        for y in 0..<from.height {
            var row: Row = [:]
            for x in 0..<from.width {
                let char = chars[y + from.minY]?[x + from.minX]
                row[x] = AttributedCharacter(character: char.map { $0.character } ?? Character(" "), attributes: [])
                guard
                    let char = char,
                    char.character != AttributedCharacter.null.character
                else { continue }
                into.write(char, at: dest + Point(x: x, y: y))

                if let mouseEvents = mouse[y]?[x] {
                    let (key, buttons): (ViewKey, [MouseEvent.Button]) = mouseEvents
                    let mouseRect = Rect(origin: dest + Point(x: x, y: y), size: Size(width: 1, height: 1))
                    into.claimMouse(key: key, rect: mouseRect, mask: mask, buttons: buttons)
                }
            }
            text[y] = row
        }
    }

    public func render<Msg>(
        key nextKey: ViewKey,
        view: View<Msg>,
        viewport: Viewport
    ) {
        let prevKey = currentKey
        currentKey = calculateNextKey(view.viewKey ?? nextKey)
        push(viewport: viewport) {
            view.render(viewport.toLocalViewport(), self)
        }
        currentKey = prevKey
    }

    public func absolute(point: Point) -> Point {
        currentOrigin + point
    }

    public func absolute(rect: Rect) -> Rect {
        Rect(
            origin: absolute(point: rect.origin),
            size: rect.size
        )
    }

    // Before a view "claims" an area, it must first get a 'mask' of the buffer – this
    // defines the part of the buffer that is available for writing and claiming
    // events. Then, write to the buffer – this gives child views a chance to claim the
    // mouse events first. Finally, claim the area using the original mask. Only
    // still-available mouse event locations will be claimable.
    //
    // The view argument is optional, in case a view is claiming an area *for itself*,
    // rather than assigning it to a child view.
    func claimMouse(
        key nextKey: ViewKey, rect: Rect, mask: Mask, buttons: [MouseEvent.Button]
    ) {
        guard buttons.count > 0 else { return }
        let initial = absolute(point: rect.origin)
        let maxPt = currentOrigin + currentMask.size
        guard
            initial.x + rect.width > currentMask.origin.x,
            initial.y + rect.height > currentMask.origin.y,
            initial.x < maxPt.x, initial.y < maxPt.y
        else { return }

        let currentKey = calculateNextKey(nextKey)
        for y in (initial.y..<initial.y + rect.height) {
            if y > maxPt.y { break }
            guard y >= currentMask.origin.y else { continue }

            var row = mouse[y] ?? [:]
            for x in (initial.x..<initial.x + rect.width) {
                if x > maxPt.x { break }
                guard
                    x >= currentMask.origin.x,
                    mask[y]?[x] != nil,
                    row[x] == nil
                else { continue }

                row[x] = (currentKey, buttons)
            }
            mouse[y] = row
        }
    }

    func checkMouse(key nextKey: ViewKey, mouse mouseEvent: MouseEvent)
        -> Bool
    {
        guard let row = mouse[mouseEvent.location.y], let claimedEvents = row[mouseEvent.location.x] else {
            return false
        }
        let currentKey = calculateNextKey(nextKey)
        let claimedEventKey = claimedEvents.0
        return claimedEventKey == currentKey && claimedEvents.1.contains(mouseEvent.button)
    }

    public func events<Msg>(key nextKey: ViewKey, event: Event, view: View<Msg>) -> ([Msg], [Event]) {
        let prevKey = currentKey
        currentKey = calculateNextKey(view.viewKey ?? nextKey)
        let events = view.events(event, self)
        currentKey = prevKey
        return events
    }

    public func store(_ model: Any) {
        models[currentKey.bufferKey] = model
    }

    public func retrieve<T>() -> T? {
        if let model = models[currentKey.bufferKey] as? T {
            return model
        } else if let model = prevModels[currentKey.bufferKey] as? T {
            models[currentKey.bufferKey] = model
            return model
        }
        return nil

    }

    public func write(_ content: Attributed, at localPt: Point) {
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
            let maskChar = mask[point.y]?[point.x],
            point.x + 1 > currentMask.origin.x, point.y + 1 > currentMask.origin.y,
            point.x < maxPt.x, point.y < maxPt.y
        else { return }

        var row = chars[point.y] ?? [:]
        let char = row[point.x] ?? AttributedCharacter.null
        guard char != AttributedCharacter.skip else { return }
        row[point.x] = modify(char).styled(maskChar.attributes)
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
                    let maskChar = mask[y]?[x],
                    char != AttributedCharacter.skip
                else { continue }
                row[x] = modify(x, y, char).styled(maskChar.attributes)
                chars[y] = row
            }
        }
    }

    func calculateNextKey(_ nextKey: ViewKey) -> ViewKey {
        currentKey.append(key: nextKey)
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

    private static func mouse(_ mouse: MouseEvents) -> String {
        var description = ""
        let height = mouse.reduce(0) { my, kv0 in
            max(my, kv0.key)
        }
        let width = mouse.reduce(0) { my, kv in
            max(
                my,
                kv.value.reduce(0) { mx, kv1 in
                    max(mx, kv1.key)
                }
            )
        }
        for y in 0...height {
            guard let row = mouse[y] else {
                description += "\n"
                continue
            }

            for x in 0...width {
                guard row[x] != nil else {
                    description += "."
                    continue
                }

                description += String("◦")
            }

            description += "↩︎\n"
        }
        return description
    }

    public var description: String {
        "currentKey: \(currentKey)\n\(Buffer.desc(chars))\n\(Buffer.mouse(mouse))"
    }
}
