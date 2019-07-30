////
///  InputView.swift
//

public class InputView: ComponentView {
    public typealias OnChangeHandler = ((String) -> AnyMessage)
    public typealias OnCursorChangeHandler = ((Cursor) -> AnyMessage)
    public typealias OnEnterHandler = (() -> AnyMessage)

    public struct Cursor {
        static func `default`(for text: String) -> Cursor {
            return Cursor(at: text.count, selection: 0)
        }

        let at: Int
        let selection: Int

        var normalized: Cursor {
            if self.selection < 0 {
                return Cursor(at: self.at + self.selection, selection: -self.selection)
            }
            else {
                return self
            }
        }
    }

    var text: String
    let size: DesiredSize
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
        for c in text {
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

    public init(at location: Location = .tl(.zero),
        size: DesiredSize = DesiredSize(),
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

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
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

    override public func merge(with prevComponent: Component) {
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
            calcWidth = max(calcWidth, line.count + 1)
            calcHeight += 1
        }

        return DesiredSize(width: size.width ?? .literal(calcWidth), height: size.height ?? .literal(max(1, calcHeight)))
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        guard rect.size.width > 0 && rect.size.height > 0 else { return }

        let normalCursor = self.cursor.normalized

        var yOffset = 0
        var xOffset = 0
        var cOffset = 0

        var cursorPoint: Point = .zero
        var setCursorPoint = false
        for char in text {
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
        if cursorPoint.x >= rect.size.width {
            xClip = rect.size.width - cursorPoint.x - 1
        }
        else {
            xClip = 0
        }
        if cursorPoint.y >= rect.size.height {
            yClip = rect.size.height - cursorPoint.y - 1
        }
        else {
            yClip = 0
        }

        yOffset = 0
        xOffset = 0
        cOffset = 0

        for char in text {
            var attrs: [Attr]
            if normalCursor.selection > 0 && cOffset >= normalCursor.at && cOffset < normalCursor.at + normalCursor.selection {
                attrs = [.reverse]
            }
            else if cOffset == normalCursor.at {
                if isFirstResponder {
                    attrs = [.underline]
                }
                else {
                    attrs = [.bold]
                }
            }
            else if isFirstResponder{
                attrs = [.bold]
            }
            else {
                attrs = [.underline]
            }

            let printableChar: String
            switch char {
            case "\n":
                printableChar = " "
            case "󰀀": // uF0000
                printableChar = "´"
                attrs.append(.reverse)
            case "󰀁": // uF0001
                printableChar = "ˆ"
                attrs.append(.reverse)
            case "󰀂": // uF0002
                printableChar = "˜"
                attrs.append(.reverse)
            case "󰀃": // uF0003
                printableChar = "¨"
                attrs.append(.reverse)
            case "󰀄": // uF0004
                printableChar = "`"
                attrs.append(.reverse)
            default:
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

        if isFirstResponder && normalCursor.at == text.count {
            buffer.write(AttrChar(" ", [.underline]), x: xOffset + xClip, y: yOffset + yClip)
        }
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        guard
            isFirstResponder
        else { return [] }

        switch event {
        case let .key(key):
            return keyEvent(key: key).compactMap { $0 }
        default:
            return []
        }
    }

    private func keyEvent(key: KeyEvent) -> [AnyMessage?] {
        if key.isPrintable {
            return insert(string: key.toPrintable)
        }
        else if key == .enter, isMultiline {
            return insert(string: key.toPrintable)
        }
        else if key == .enter, let onEnter = onEnter {
            return [onEnter()]
        }
        else if key == .backspace {
            return backspace()
        }
        else if key == .signalEot { // ctrl+d == delete
            return delete()
        }
        else if key == .left {
            return moveLeft()
        }
        else if key == .right {
            return moveRight()
        }
        else if key == .shift(.left) {
            return extendLeft()
        }
        else if key == .shift(.right) {
            return extendRight()
        }
        else if key == .up || key == .shift(.up) {
            return moveUp(extend: key == .shift(.up))
        }
        else if key == .down || key == .shift(.down) {
            return moveDown(extend: key == .shift(.down))
        }
        else if key == .ctrl(.a) {
            return moveToTop()
        }
        else if key == .ctrl(.e) {
            return moveToBottom()
        }
        else if key == .home {
            return moveToBeginOfLine()
        }
        else if key == .end {
            return moveToEndOfLine()
        }
        return []
    }

    private func insert(string insert: String) -> [AnyMessage?] {
        let offset = insert.count
        if cursor.at == text.count && cursor.selection == 0 {
            let nextText = text + insert
            cursor = Cursor(at: cursor.at + offset, selection: 0)
            (text, cursor) = fixDiacritics(nextText, cursor: cursor)
            return [onCursorChange?(cursor), onChange(text)]
        }

        let normalCursor = cursor.normalized
        // weird escape sequences can cause this:
        guard normalCursor.at < text.count else { return [] }

        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let end = text.index(cursorStart, offsetBy: normalCursor.selection)
        let nextText = text.replacingCharacters(in: cursorStart..<end, with: insert)
        cursor = Cursor(at: normalCursor.at + offset, selection: 0)
        (text, cursor) = fixDiacritics(nextText, cursor: cursor)
        return [onCursorChange?(cursor), onChange(text)]
    }

    private func backspace() -> [AnyMessage?] {
        guard cursor.at > 0 || cursor.selection > 0 else { return [] }

        let normalCursor = cursor.normalized
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let range: Range<String.Index>
        if normalCursor.selection == 0 {
            let prev = text.index(cursorStart, offsetBy: -1)
            range = prev ..< cursorStart
            cursor = Cursor(at: normalCursor.at - 1, selection: 0)
        }
        else {
            let end = text.index(cursorStart, offsetBy: normalCursor.selection)
            range = cursorStart ..< end
            cursor = Cursor(at: normalCursor.at, selection: 0)
        }
        let nextText = text.replacingCharacters(in: range, with: "")
        (text, cursor) = fixDiacritics(nextText, cursor: cursor)
        return [onCursorChange?(cursor), onChange(text)]
    }

    private func delete() -> [AnyMessage?] {
        if cursor.at == text.count && cursor.selection == 0 { return [] }

        let normalCursor = cursor.normalized
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let range: Range<String.Index>
        if normalCursor.selection == 0 {
            let next = text.index(cursorStart, offsetBy: 1)
            range = cursorStart ..< next
            cursor = Cursor(at: normalCursor.at, selection: 0)
        }
        else {
            let end = text.index(cursorStart, offsetBy: normalCursor.selection)
            range = cursorStart ..< end
            cursor = Cursor(at: normalCursor.at, selection: 0)
        }
        let nextText = text.replacingCharacters(in: range, with: "")
        (text, cursor) = fixDiacritics(nextText, cursor: cursor)
        return [onCursorChange?(cursor), onChange(text)]
    }

    private func moveLeft() -> [AnyMessage?] {
        let normalCursor = cursor.normalized
        if cursor.selection == 0 {
            cursor = Cursor(at: max(cursor.at - 1, 0), selection: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
        else {
            cursor = Cursor(at: normalCursor.at, selection: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
    }

    private func moveRight() -> [AnyMessage?] {
        let normalCursor = cursor.normalized
        if cursor.selection == 0 {
            let maxCursor = text.count
            cursor = Cursor(at: min(cursor.at + 1, maxCursor), selection: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
        else {
            cursor = Cursor(at: normalCursor.at + normalCursor.selection, selection: 0)
            return [onCursorChange?(cursor), SystemMessage.rerender]
        }
    }

    private func extendLeft() -> [AnyMessage?] {
        if cursor.at + cursor.selection == 0 { return [] }
        cursor = Cursor(at: cursor.at, selection: cursor.selection - 1)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func extendRight() -> [AnyMessage?] {
        let maxCursor = text.count
        if cursor.at + cursor.selection == maxCursor { return [] }
        cursor = Cursor(at: cursor.at, selection: cursor.selection + 1)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveUp(extend: Bool) -> [AnyMessage?] {
        let lines = textLines
        var x = 0
        var prevX = 0
        var prevLength = 0
        let maxX = cursor.at + cursor.selection
        for line in lines {
            let selection = line.count + 1
            if x + selection > maxX {
                let lineOffset = maxX - x
                x = prevX + min(lineOffset, prevLength)
                break
            }
            prevLength = selection - 1
            prevX = x
            x += selection
        }

        let prevCursor = cursor
        if extend {
            if x == 0 {
                cursor = Cursor(at: cursor.at, selection: extend ? -cursor.at : 0)
            }
            else {
                cursor = Cursor(at: cursor.at, selection: x - cursor.at)
            }
        }
        else if x == 0 {
            cursor = Cursor(at: 0, selection: 0)
        }
        else {
            cursor = Cursor(at: x, selection: 0)
        }

        if prevCursor.at == cursor.at && prevCursor.selection == cursor.selection {
            return []
        }
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveDown(extend: Bool) -> [AnyMessage?] {
        let lines = textLines
        var x = 0
        var prevX = 0
        let maxX = cursor.at + cursor.selection
        for line in lines {
            let selection = line.count
            if x > maxX {
                let lineOffset = maxX - prevX
                x += min(lineOffset, selection)
                break
            }
            prevX = x
            x += selection + 1
        }

        let prevCursor = cursor
        if extend {
            if x > text.count {
                cursor = Cursor(at: cursor.at, selection: text.count - cursor.at)
            }
            else {
                cursor = Cursor(at: cursor.at, selection: x - cursor.at)
            }
        }
        else if x > text.count {
            cursor = Cursor(at: text.count, selection: 0)
        }
        else {
            cursor = Cursor(at: x, selection: 0)
        }

        if prevCursor.at == cursor.at && prevCursor.selection == cursor.selection {
            return []
        }
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveToTop() -> [AnyMessage?] {
        guard cursor.at != 0 || cursor.selection != 0 else { return [] }

        cursor = Cursor(at: 0, selection: 0)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveToBottom() -> [AnyMessage?] {
        guard cursor.at != text.count || cursor.selection != 0 else { return [] }

        cursor = Cursor(at: text.count, selection: 0)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveToBeginOfLine() -> [AnyMessage?] {
        guard cursor.at != 0 || cursor.selection != 0 else { return [] }

        cursor = Cursor(at: 0, selection: 0)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    private func moveToEndOfLine() -> [AnyMessage?] {
        guard cursor.at != text.count || cursor.selection != 0 else { return [] }

        cursor = Cursor(at: text.count, selection: 0)
        return [onCursorChange?(cursor), SystemMessage.rerender]
    }

    override public func shouldStopProcessing(event: Event) -> Bool {
        guard
            isFirstResponder,
            case let .key(key) = event
        else { return false }

        if key.isPrintable ||
            (isMultiline && key == .enter) ||
            key == .backspace ||
            key == .signalEot ||
            key == .left ||
            key == .right ||
            key == .shift(.left) ||
            key == .shift(.right) ||
            key == .up ||
            key == .shift(.up) ||
            key == .shift(.up) ||
            key == .down ||
            key == .shift(.down) ||
            key == .shift(.down) ||
            key == .enter ||
            key == .home ||
            key == .end ||
            key == .ctrl(.a) ||
            key == .ctrl(.e)
        {
            return true
        }

        return false
    }
}

private func fixDiacritics(_ text: String, cursor: InputView.Cursor) -> (String, InputView.Cursor) {
    let newText = text
        // ´ áéíóú
        .replacingOccurrences(of: "󰀀A", with: "Á")
        .replacingOccurrences(of: "󰀀E", with: "É")
        .replacingOccurrences(of: "󰀀I", with: "Í")
        .replacingOccurrences(of: "󰀀O", with: "Ó")
        .replacingOccurrences(of: "󰀀U", with: "Ú")
        .replacingOccurrences(of: "󰀀Y", with: "Ý")
        .replacingOccurrences(of: "󰀀a", with: "á")
        .replacingOccurrences(of: "󰀀e", with: "é")
        .replacingOccurrences(of: "󰀀i", with: "í")
        .replacingOccurrences(of: "󰀀o", with: "ó")
        .replacingOccurrences(of: "󰀀u", with: "ú")
        .replacingOccurrences(of: "󰀀y", with: "ý")
        .replacingOccurrences(of: "󰀀C", with: "Ć")
        .replacingOccurrences(of: "󰀀c", with: "ć")
        .replacingOccurrences(of: "󰀀L", with: "Ĺ")
        .replacingOccurrences(of: "󰀀l", with: "ĺ")
        .replacingOccurrences(of: "󰀀N", with: "Ń")
        .replacingOccurrences(of: "󰀀n", with: "ń")
        .replacingOccurrences(of: "󰀀R", with: "Ŕ")
        .replacingOccurrences(of: "󰀀r", with: "ŕ")
        .replacingOccurrences(of: "󰀀S", with: "Ś")
        .replacingOccurrences(of: "󰀀s", with: "ś")
        .replacingOccurrences(of: "󰀀Z", with: "Ź")
        .replacingOccurrences(of: "󰀀z", with: "ź")
        .replacingOccurrences(of: "󰀀G", with: "Ǵ")
        .replacingOccurrences(of: "󰀀g", with: "ǵ")
        .replacingOccurrences(of: "󰀀Æ", with: "Ǽ")
        .replacingOccurrences(of: "󰀀æ", with: "ǽ")
        .replacingOccurrences(of: "󰀀K", with: "Ḱ")
        .replacingOccurrences(of: "󰀀k", with: "ḱ")
        .replacingOccurrences(of: "󰀀M", with: "Ḿ")
        .replacingOccurrences(of: "󰀀m", with: "ḿ")
        .replacingOccurrences(of: "󰀀P", with: "Ṕ")
        .replacingOccurrences(of: "󰀀p", with: "ṕ")
        .replacingOccurrences(of: "󰀀W", with: "Ẃ")
        .replacingOccurrences(of: "󰀀w", with: "ẃ")
        // ˆ âêîôû
        .replacingOccurrences(of: "󰀁A", with: "Â")
        .replacingOccurrences(of: "󰀁E", with: "Ê")
        .replacingOccurrences(of: "󰀁I", with: "Î")
        .replacingOccurrences(of: "󰀁O", with: "Ô")
        .replacingOccurrences(of: "󰀁U", with: "Û")
        .replacingOccurrences(of: "󰀁a", with: "â")
        .replacingOccurrences(of: "󰀁e", with: "ê")
        .replacingOccurrences(of: "󰀁i", with: "î")
        .replacingOccurrences(of: "󰀁o", with: "ô")
        .replacingOccurrences(of: "󰀁u", with: "û")
        .replacingOccurrences(of: "󰀁C", with: "Ĉ")
        .replacingOccurrences(of: "󰀁c", with: "ĉ")
        .replacingOccurrences(of: "󰀁G", with: "Ĝ")
        .replacingOccurrences(of: "󰀁g", with: "ĝ")
        .replacingOccurrences(of: "󰀁H", with: "Ĥ")
        .replacingOccurrences(of: "󰀁h", with: "ĥ")
        .replacingOccurrences(of: "󰀁J", with: "Ĵ")
        .replacingOccurrences(of: "󰀁j", with: "ĵ")
        .replacingOccurrences(of: "󰀁S", with: "Ŝ")
        .replacingOccurrences(of: "󰀁s", with: "ŝ")
        .replacingOccurrences(of: "󰀁W", with: "Ŵ")
        .replacingOccurrences(of: "󰀁w", with: "ŵ")
        .replacingOccurrences(of: "󰀁Y", with: "Ŷ")
        .replacingOccurrences(of: "󰀁y", with: "ŷ")
        // ˜ ñãõ
        .replacingOccurrences(of: "󰀂A", with: "Ã")
        .replacingOccurrences(of: "󰀂N", with: "Ñ")
        .replacingOccurrences(of: "󰀂O", with: "Õ")
        .replacingOccurrences(of: "󰀂a", with: "ã")
        .replacingOccurrences(of: "󰀂n", with: "ñ")
        .replacingOccurrences(of: "󰀂o", with: "õ")
        .replacingOccurrences(of: "󰀂I", with: "Ĩ")
        .replacingOccurrences(of: "󰀂i", with: "ĩ")
        .replacingOccurrences(of: "󰀂U", with: "Ũ")
        .replacingOccurrences(of: "󰀂u", with: "ũ")
        // ¨ äëïöü
        .replacingOccurrences(of: "󰀃A", with: "Ä")
        .replacingOccurrences(of: "󰀃E", with: "Ë")
        .replacingOccurrences(of: "󰀃I", with: "Ï")
        .replacingOccurrences(of: "󰀃O", with: "Ö")
        .replacingOccurrences(of: "󰀃U", with: "Ü")
        .replacingOccurrences(of: "󰀃a", with: "ä")
        .replacingOccurrences(of: "󰀃e", with: "ë")
        .replacingOccurrences(of: "󰀃i", with: "ï")
        .replacingOccurrences(of: "󰀃o", with: "ö")
        .replacingOccurrences(of: "󰀃u", with: "ü")
        .replacingOccurrences(of: "󰀃Y", with: "Ÿ")
        .replacingOccurrences(of: "󰀃y", with: "ÿ")
        .replacingOccurrences(of: "󰀃W", with: "Ẅ")
        .replacingOccurrences(of: "󰀃w", with: "ẅ")
        .replacingOccurrences(of: "󰀃X", with: "Ẍ")
        .replacingOccurrences(of: "󰀃x", with: "ẍ")
        .replacingOccurrences(of: "󰀃t", with: "ẗ")
        .replacingOccurrences(of: "󰀃H", with: "Ḧ")
        .replacingOccurrences(of: "󰀃h", with: "ḧ")
        .replacingOccurrences(of: "󰀃3", with: "Ӟ")
        // ` àèìòù
        .replacingOccurrences(of: "󰀄A", with: "À")
        .replacingOccurrences(of: "󰀄E", with: "È")
        .replacingOccurrences(of: "󰀄I", with: "Ì")
        .replacingOccurrences(of: "󰀄O", with: "Ò")
        .replacingOccurrences(of: "󰀄U", with: "Ù")
        .replacingOccurrences(of: "󰀄a", with: "à")
        .replacingOccurrences(of: "󰀄e", with: "è")
        .replacingOccurrences(of: "󰀄i", with: "ì")
        .replacingOccurrences(of: "󰀄o", with: "ò")
        .replacingOccurrences(of: "󰀄u", with: "ù")
        .replacingOccurrences(of: "󰀄N", with: "Ǹ")
        .replacingOccurrences(of: "󰀄n", with: "ǹ")
        .replacingOccurrences(of: "󰀄W", with: "Ẁ")
        .replacingOccurrences(of: "󰀄w", with: "ẁ")
        .replacingOccurrences(of: "󰀄Y", with: "Ỳ")
        .replacingOccurrences(of: "󰀄y", with: "ỳ")
    if newText != text {
        return (newText, InputView.Cursor(
            at: cursor.at - text.count + newText.count,
            selection: 0
            ))
    }
    else {
        return (text, cursor)
    }
}
