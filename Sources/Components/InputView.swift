////
///  InputView.swift
//

class InputView: ComponentView {
    typealias OnChangeHandler = ((Model) -> AnyMessage)
    typealias OnEnterHandler = (() -> AnyMessage)

    struct Model {
        static let `default` = Model(text: "")

        let text: String
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
    }

    struct Cursor {
        static func `default`(for model: InputView.Model) -> Cursor {
            return Cursor(at: model.text.characters.count, length: 0)
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
    let model: Model
    var cursor: Cursor
    /// If `forceCursor` is assigned, it will overide the auto-updating cursor
    let forceCursor: Cursor?
    let isFirstResponder: Bool
    let multiline: Bool
    var onChange: OnChangeHandler
    var onEnter: OnEnterHandler?

    init(_ location: Location,
        _ size: DesiredSize = DesiredSize(),
        model: Model = Model.default,
        isFirstResponder: Bool = false,
        multiline: Bool = false,
        cursor: Cursor? = nil,
        onChange: @escaping OnChangeHandler,
        onEnter: OnEnterHandler? = nil
        ) {
        self.size = size
        self.model = model
        self.onChange = onChange
        self.onEnter = onEnter
        self.isFirstResponder = isFirstResponder
        self.multiline = multiline
        self.forceCursor = cursor
        self.cursor = cursor ?? Cursor.default(for: model)
        super.init()
        self.location = location
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> InputView {
        let component = self
        let myChange = self.onChange
        let onChange: OnChangeHandler = { model in
            return mapper(myChange(model) as! T)
        }
        component.onChange = onChange
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
        for line in model.textLines {
            calcWidth = max(calcWidth, line.characters.count)
            calcHeight += 1
        }
        return DesiredSize(width: calcWidth, height: calcHeight)
    }

    override func chars(in size: Size) -> Screen.Chars {
        let normalCursor = self.cursor.normal
        var yOffset = 0
        var xOffset = 0
        var cOffset = 0
        var chars = model.text.characters.reduce(Screen.Chars()) { (memo, char) in
            if yOffset >= size.height { return memo }

            var next = memo
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

            if xOffset < size.width {
                var row = memo[yOffset] ?? [:]
                row[xOffset] = Text(printableChar, attrs: attrs)
                next[yOffset] = row
            }

            if char == "\n" {
                yOffset += 1
                xOffset = 0
            }
            else {
                xOffset += 1
            }

            cOffset += 1
            return next
        }

        if isFirstResponder && normalCursor.at == model.text.characters.count && yOffset < size.height {
            var row = chars[yOffset] ?? [:]
            row[xOffset] = Text(" ", attrs: [.underline])
            chars[yOffset] = row
        }
        return chars
    }

    override func messages(for event: Event) -> [AnyMessage] {
        guard
            isFirstResponder
        else { return [] }

        switch event {
        case let .key(key):
            return keyEvent(onChange, key: key)
        default:
            return []
        }
    }

    private func keyEvent(_ onChange: OnChangeHandler, key: KeyEvent) -> [AnyMessage] {
        if key.isPrintable || (key == .key_enter && multiline) {
            return insert(onChange, string: key.toString)
        }
        else if key == .key_enter, let onEnter = onEnter {
            return [onEnter()]
        }
        else if key == .key_backspace {
            return backspace(onChange)
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

    private func insert(_ onChange: OnChangeHandler, string insert: String) -> [AnyMessage] {
        let offset = insert.characters.count
        let text = model.text
        if cursor.at == text.characters.count && cursor.length == 0 {
            let nextText = text + insert
            cursor = Cursor(at: cursor.at + offset, length: 0)
            return [onChange(Model(text: nextText))]
        }

        let normalCursor = cursor.normal
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let end = text.index(cursorStart, offsetBy: normalCursor.length)
        let nextText = text.replacingCharacters(in: cursorStart..<end, with: insert)
        self.cursor = Cursor(at: normalCursor.at + offset, length: 0)
        return [onChange(Model(text: nextText))]
    }

    private func backspace(_ onChange: OnChangeHandler) -> [AnyMessage] {
        if cursor.at == 0 && cursor.length == 0 { return [] }

        let text = model.text
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
        return [onChange(Model(text: nextText))]
    }

    private func moveLeft(_ onChange: OnChangeHandler) -> [AnyMessage] {
        let normalCursor = cursor.normal
        if cursor.length == 0 {
            cursor = Cursor(at: max(cursor.at - 1, 0), length: 0)
            return [SystemMessage.rerender]
        }
        else {
            cursor = Cursor(at: normalCursor.at, length: 0)
            return [SystemMessage.rerender]
        }
    }

    private func moveRight(_ onChange: OnChangeHandler) -> [AnyMessage] {
        let normalCursor = cursor.normal
        let text = model.text
        if cursor.length == 0 {
            let maxCursor = text.characters.count
            cursor = Cursor(at: min(cursor.at + 1, maxCursor), length: 0)
            return [SystemMessage.rerender]
        }
        else {
            cursor = Cursor(at: normalCursor.at + normalCursor.length, length: 0)
            return [SystemMessage.rerender]
        }
    }

    private func extendLeft(_ onChange: OnChangeHandler) -> [AnyMessage] {
        if cursor.at + cursor.length == 0 { return [] }
        cursor = Cursor(at: cursor.at, length: cursor.length - 1)
        return [SystemMessage.rerender]
    }

    private func extendRight(_ onChange: OnChangeHandler) -> [AnyMessage] {
        let text = model.text
        let maxCursor = text.characters.count
        if cursor.at + cursor.length == maxCursor { return [] }
        cursor = Cursor(at: cursor.at, length: cursor.length + 1)
        return [SystemMessage.rerender]
    }

    private func moveUp(_ onChange: OnChangeHandler, extend: Bool) -> [AnyMessage] {
        let lines = model.textLines
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
        return [SystemMessage.rerender]
    }

    private func moveDown(_ onChange: OnChangeHandler, extend: Bool) -> [AnyMessage] {
        let text = model.text
        let lines = model.textLines
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
        return [SystemMessage.rerender]
    }

    private func moveToBeginning(_ onChange: OnChangeHandler) -> [AnyMessage] {
        cursor = Cursor(at: 0, length: 0)
        return [SystemMessage.rerender]
    }

    private func moveToEnd(_ onChange: OnChangeHandler) -> [AnyMessage] {
        cursor = Cursor(at: model.text.characters.count, length: 0)
        return [SystemMessage.rerender]
    }
}

extension InputView: KeyboardTrapComponent {
    func shouldAccept(key: KeyEvent) -> Bool {
        guard isFirstResponder else { return false }

        if key.isPrintable ||
            multiline && key == .key_enter ||
            key == .key_backspace ||
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
