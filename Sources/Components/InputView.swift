////
///  InputView.swift
//

class InputView: ComponentView {
    typealias OnChangeHandler = ((String) -> AnyMessage)
    typealias OnCursorChangeHandler = ((Cursor) -> AnyMessage)
    typealias OnEnterHandler = (() -> AnyMessage)

    struct Cursor {
        static func `default`(for text: String) -> Cursor {
            return Cursor(at: text.characters.count, length: 0)
        }

        let at: Int
        let length: Int

        var normal: Cursor {
            if self.length < 0 {
                return Cursor(at: self.at + self.length, length: -self.length)
            }
            else {
                return self
            }
        }
    }

    let size: DesiredSize
    let text: String
    var cursor: Cursor
    /// If `forceCursor` is assigned, it will overide the auto-updating cursor
    let forceCursor: Cursor?
    let isFirstResponder: Bool
    let isMultiline: Bool
    var onChange: OnChangeHandler
    var onCursorChange: OnCursorChangeHandler?
    var onEnter: OnEnterHandler?

    var textLines: [String] {
        var line = ""
        var lines: [String] = []
        for c in text.characters {
            if c == "\n" {
                lines.append(line)
                line = ""
            }
            else {
                line += String(c)
            }
        }
        lines.append(line)
        return lines
    }

    init(_ location: Location = .tl(.zero),
        _ size: DesiredSize = DesiredSize(),
        text: String = "",
        isFirstResponder: Bool = false,
        isMultiline: Bool = false,
        cursor: Cursor? = nil,
        onChange: @escaping OnChangeHandler,
        onCursorChange: OnCursorChangeHandler? = nil,
        onEnter: OnEnterHandler? = nil
        ) {
        self.size = size
        self.text = text
        self.onChange = onChange
        self.onCursorChange = onCursorChange
        self.onEnter = onEnter
        self.isFirstResponder = isFirstResponder
        self.isMultiline = isMultiline
        self.forceCursor = cursor
        self.cursor = cursor ?? Cursor.default(for: text)
        super.init()
        self.location = location
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> InputView {
        let component = self
        let myChange = self.onChange
        let onChange: OnChangeHandler = { text in
            return mapper(myChange(text) as! T)
        }
        component.onChange = onChange

        if let onCursorChange = onCursorChange {
            let myCursorChange = onCursorChange
            let onCursorChange: OnCursorChangeHandler = { cursor in
                return mapper(myCursorChange(cursor) as! T)
            }
            component.onCursorChange = onCursorChange
        }

        if let onEnter = onEnter {
            let myEnter = onEnter
            let onEnter: OnEnterHandler = {
                return mapper(myEnter() as! T)
            }
            component.onEnter = onEnter
        }

        return component
    }

    override func merge(with prevComponent: Component) {
        guard let prevInput = prevComponent as? InputView else { return }

        cursor = forceCursor ?? prevInput.cursor
    }

    override func desiredSize() -> DesiredSize {
        if let width = size.width, let height = size.height {
            return DesiredSize(width: width, height: height)
        }

        var calcWidth = 0
        var calcHeight = 0
        for line in textLines {
            calcWidth = max(calcWidth, line.characters.count + 1)
            calcHeight += 1
        }

        return DesiredSize(width: calcWidth, height: max(1, calcHeight))
    }

    override func render(in buffer: Buffer, size: Size) {
        guard size.width > 0 && size.height > 0 else { return }

        let normalCursor = self.cursor.normal

        var yOffset = 0
        var xOffset = 0
        var cOffset = 0

        var cursorPoint: Point = .zero
        var setCursorPoint = false
        for char in text.characters {
            if cOffset == normalCursor.at {
                setCursorPoint = true
                cursorPoint = Point(x: xOffset, y: yOffset)
                break
            }

            if char == "\n" {
                yOffset += 1
                xOffset = 0
            }
            else {
                xOffset += 1
            }

            cOffset += 1
        }
        if !setCursorPoint {
            cursorPoint = Point(x: xOffset, y: yOffset)
        }

        let xClip: Int, yClip: Int
        if cursorPoint.x >= size.width {
            xClip = size.width - cursorPoint.x - 1
        }
        else {
            xClip = 0
        }
        if cursorPoint.y >= size.height {
            yClip = size.height - cursorPoint.y - 1
        }
        else {
            yClip = 0
        }

        yOffset = 0
        xOffset = 0
        cOffset = 0

        for char in text.characters {
            let attrs: [Attr]
            if normalCursor.length > 0 && cOffset >= normalCursor.at && cOffset < normalCursor.at + normalCursor.length {
                attrs = [.reverse]
            }
            else if cOffset == normalCursor.at {
                if isFirstResponder {
                    attrs = [.underline]
                }
                else {
                    attrs = []
                }
            }
            else if isFirstResponder{
                attrs = []
            }
            else {
                attrs = [.underline]
            }

            let printableChar: String
            if char == "\n" {
                printableChar = " "
            }
            else {
                printableChar = String(char)
            }

            buffer.write(AttrChar(printableChar, attrs), x: xClip + xOffset, y: yClip + yOffset)

            if char == "\n" {
                yOffset += 1
                xOffset = 0
            }
            else {
                xOffset += 1
            }

            cOffset += 1
        }

        if isFirstResponder && normalCursor.at == text.characters.count {
            buffer.write(AttrChar(" ", [.underline]), x: xOffset + xClip, y: yOffset + yClip)
        }
    }

    override func messages(for event: Event) -> [AnyMessage] {
        guard
            isFirstResponder
        else { return [] }

        switch event {
        case let .key(key):
            return keyEvent(onChange, key: key).flatMap { $0 }
        default:
            return []
        }
    }

    private func keyEvent(_ onChange: OnChangeHandler, key: KeyEvent) -> [AnyMessage?] {
        if key.isPrintable || (key == .key_enter && isMultiline) {
            return insert(onChange, string: key.toString)
        }
        else if key == .key_enter, let onEnter = onEnter {
            return [onEnter()]
        }
        else if key == .key_backspace {
            return backspace(onChange)
        }
        else if key == .signal_eot { // ctrl+d == delete
            return delete(onChange)
        }
        else if key == .key_left {
            return moveLeft(onChange)
        }
        else if key == .key_right {
            return moveRight(onChange)
        }
        else if key == .key_shift_left {
            return extendLeft(onChange)
        }
        else if key == .key_shift_right {
            return extendRight(onChange)
        }
        else if key == .key_up || key == .key_shift_up {
            return moveUp(onChange, extend: key == .key_shift_up)
        }
        else if key == .key_down || key == .key_shift_down {
            return moveDown(onChange, extend: key == .key_shift_down)
        }
        else if key == .signal_ctrl_a {
            return moveToBeginning(onChange)
        }
        else if key == .signal_ctrl_e {
            return moveToEnd(onChange)
        }
        return []
    }

    private func insert(_ onChange: OnChangeHandler, string insert: String) -> [AnyMessage?] {
        let offset = insert.characters.count
        if cursor.at == text.characters.count && cursor.length == 0 {
            let nextText = text + insert
            cursor = Cursor(at: cursor.at + offset, length: 0)
            return [onCursorChange?(cursor), onChange(nextText)]
        }

        let normalCursor = cursor.normal
        // weird escape sequences can cause this:
        guard normalCursor.at < text.characters.count else { return [] }

        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let end = text.index(cursorStart, offsetBy: normalCursor.length)
        let nextText = text.replacingCharacters(in: cursorStart..<end, with: insert)
        cursor = Cursor(at: normalCursor.at + offset, length: 0)
        return [onCursorChange?(cursor), onChange(nextText)]
    }

    private func backspace(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        if cursor.at == 0 && cursor.length == 0 { return [] }

        let normalCursor = cursor.normal
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let range: Range<String.Index>
        if normalCursor.length == 0 {
            let prev = text.index(cursorStart, offsetBy: -1)
            range = prev ..< cursorStart
            cursor = Cursor(at: normalCursor.at - 1, length: 0)
        }
        else {
            let end = text.index(cursorStart, offsetBy: normalCursor.length)
            range = cursorStart ..< end
            cursor = Cursor(at: normalCursor.at, length: 0)
        }
        let nextText = text.replacingCharacters(in: range, with: "")
        return [onCursorChange?(cursor), onChange(nextText)]
    }

    private func delete(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        if cursor.at == text.characters.count && cursor.length == 0 { return [] }

        let normalCursor = cursor.normal
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let range: Range<String.Index>
        if normalCursor.length == 0 {
            let next = text.index(cursorStart, offsetBy: 1)
            range = cursorStart ..< next
            cursor = Cursor(at: normalCursor.at, length: 0)
        }
        else {
            let end = text.index(cursorStart, offsetBy: normalCursor.length)
            range = cursorStart ..< end
            cursor = Cursor(at: normalCursor.at, length: 0)
        }
        let nextText = text.replacingCharacters(in: range, with: "")
        return [onCursorChange?(cursor), onChange(nextText)]
    }

    private func moveLeft(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        let normalCursor = cursor.normal
        if cursor.length == 0 {
            cursor = Cursor(at: max(cursor.at - 1, 0), length: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
        else {
            cursor = Cursor(at: normalCursor.at, length: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
    }

    private func moveRight(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        let normalCursor = cursor.normal
        if cursor.length == 0 {
            let maxCursor = text.characters.count
            cursor = Cursor(at: min(cursor.at + 1, maxCursor), length: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
        else {
            cursor = Cursor(at: normalCursor.at + normalCursor.length, length: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
    }

    private func extendLeft(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        if cursor.at + cursor.length == 0 { return [] }
        cursor = Cursor(at: cursor.at, length: cursor.length - 1)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func extendRight(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        let maxCursor = text.characters.count
        if cursor.at + cursor.length == maxCursor { return [] }
        cursor = Cursor(at: cursor.at, length: cursor.length + 1)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveUp(_ onChange: OnChangeHandler, extend: Bool) -> [AnyMessage?] {
        let lines = textLines
        var x = 0
        var prevX = 0
        var prevLength = 0
        let maxX = cursor.at + cursor.length
        for line in lines {
            let length = line.characters.count + 1
            if x + length > maxX {
                let lineOffset = maxX - x
                x = prevX + min(lineOffset, prevLength)
                break
            }
            prevLength = length - 1
            prevX = x
            x += length
        }

        let prevCursor = cursor
        if extend {
            if x == 0 {
                cursor = Cursor(at: cursor.at, length: extend ? -cursor.at : 0)
            }
            else {
                cursor = Cursor(at: cursor.at, length: x - cursor.at)
            }
        }
        else if x == 0 {
            cursor = Cursor(at: 0, length: 0)
        }
        else {
            cursor = Cursor(at: x, length: 0)
        }

        if prevCursor.at == cursor.at && prevCursor.length == cursor.length {
            return []
        }
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveDown(_ onChange: OnChangeHandler, extend: Bool) -> [AnyMessage?] {
        let lines = textLines
        var x = 0
        var prevX = 0
        let maxX = cursor.at + cursor.length
        for line in lines {
            let length = line.characters.count
            if x > maxX {
                let lineOffset = maxX - prevX
                x += min(lineOffset, length)
                break
            }
            prevX = x
            x += length + 1
        }

        let prevCursor = cursor
        if extend {
            if x > text.characters.count {
                cursor = Cursor(at: cursor.at, length: text.characters.count - cursor.at)
            }
            else {
                cursor = Cursor(at: cursor.at, length: x - cursor.at)
            }
        }
        else if x > text.characters.count {
            cursor = Cursor(at: text.characters.count, length: 0)
        }
        else {
            cursor = Cursor(at: x, length: 0)
        }

        if prevCursor.at == cursor.at && prevCursor.length == cursor.length {
            return []
        }
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveToBeginning(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        guard cursor.at != 0 || cursor.length != 0 else { return [] }

        cursor = Cursor(at: 0, length: 0)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveToEnd(_ onChange: OnChangeHandler) -> [AnyMessage?] {
        guard cursor.at != text.characters.count || cursor.length != 0 else { return [] }

        cursor = Cursor(at: text.characters.count, length: 0)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }
}

extension InputView: KeyboardTrapComponent {
    func shouldAccept(key: KeyEvent) -> Bool {
        guard isFirstResponder else { return false }

        if key.isPrintable ||
            isMultiline && key == .key_enter ||
            key == .key_backspace ||
            key == .signal_eot ||
            key == .key_left ||
            key == .key_right ||
            key == .key_shift_left ||
            key == .key_shift_right ||
            key == .key_up ||
            key == .key_shift_up ||
            key == .key_shift_up ||
            key == .key_down ||
            key == .key_shift_down ||
            key == .key_shift_down ||
            key == .key_enter ||
            key == .signal_ctrl_a ||
            key == .signal_ctrl_e
        {
            return true
        }

        return false
    }
}
