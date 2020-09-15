////
///  Input.swift
//

public enum InputOption {
    case placeholder(String)
    case wrap(Bool)
    case isMultiline(Bool)
    case isResponder(Bool)
    case style(Attr)
    case styles([Attr])
}


struct InputModel {
    static var clipboard: String = ""
    let text: String
    let isMultiline: Bool
    let cursor: TextCursor

    func replace(text: String) -> InputModel {
        InputModel(text: text, isMultiline: isMultiline, cursor: cursor)
    }

    func replace(cursor: TextCursor) -> InputModel {
        InputModel(text: text, isMultiline: isMultiline, cursor: cursor)
    }
}

public typealias OnInputChangeHandler<Msg> = ((String) -> Msg)
public typealias OnInputCursorChangeHandler<Msg> = ((TextCursor) -> Msg)
public typealias OnInputEnterHandler<Msg> = (() -> Msg)

public struct TextCursor {
    static func `default`(for text: String) -> TextCursor {
        TextCursor(at: text.count, selection: 0)
    }

    let at: Int
    let selection: Int

    var normalized: TextCursor {
        if self.selection < 0 {
            return TextCursor(at: self.at + self.selection, selection: -self.selection)
        } else {
            return self
        }
    }
}

public func Input<Msg>(
    _ text: String, onChange: @escaping (String) -> Msg, _ options: InputOption...
) -> View<Msg> {
    var wrap = false
    var isMultiline = false
    var isResponder = false
    var placeholder = ""
    var extraAttrs: [Attr] = []
    for opt in options {
        switch opt {
        case let .wrap(wrapOpt):
            wrap = wrapOpt
        case let .isMultiline(isMultilineOpt):
            isMultiline = isMultilineOpt
        case let .isResponder(isResponderOpt):
            isResponder = isResponderOpt
        case let .placeholder(placeholderOpt):
            placeholder = placeholderOpt
        case let .style(attrsOpt):
            extraAttrs = extraAttrs + [attrsOpt]
        case let .styles(attrsOpt):
            extraAttrs += attrsOpt
        }
    }

    let displayText = !isResponder && text.isEmpty ? placeholder : text
    let textView: View<Msg> = Text(displayText, .wrap(wrap))
    return View(
        preferredSize: { textView.preferredSize($0).grow(width: isResponder ? 1 : 0) },
        render: { viewport, buffer in
            guard !viewport.isEmpty else { return }


            let model: InputModel
            if let prevModel: InputModel = buffer.retrieve(), text.count == prevModel.text.count {
                model = InputModel(
                    text: text, isMultiline: isMultiline, cursor: prevModel.cursor)
            } else {
                model = InputModel(
                    text: text, isMultiline: isMultiline, cursor: TextCursor.default(for: text))
            }
            let normalCursor = model.cursor.normalized

            var yOffset = 0
            var xOffset = 0
            var cOffset = 0

            var cursorPoint: Point = .zero
            let currentText: String
            if model.text.isEmpty {
                currentText = placeholder
            } else if wrap {
                currentText = model.text.insertNewlines(fitting: viewport.size.width).string
            } else {
                currentText = model.text
            }

            if isResponder {
                var didSetCursor = false
                for char in currentText {
                    if cOffset == normalCursor.at {
                        didSetCursor = true
                        cursorPoint = Point(x: xOffset, y: yOffset)
                        break
                    }

                    if char == "\n" {
                        yOffset += 1
                        xOffset = 0
                    } else {
                        xOffset += Buffer.displayWidth(of: char)
                    }

                    cOffset += 1
                }
                if !didSetCursor {
                    cursorPoint = Point(x: xOffset, y: yOffset)
                }
            } else {
                cursorPoint = .zero
            }

            let xClip: Int
            let yClip: Int
            if cursorPoint.x >= viewport.size.width {
                xClip = viewport.size.width - cursorPoint.x - 1
            } else {
                xClip = 0
            }
            if cursorPoint.y >= viewport.size.height {
                yClip = viewport.size.height - cursorPoint.y - 1
            } else {
                yClip = 0
            }

            yOffset = 0
            xOffset = 0
            cOffset = 0

            for char in currentText {
                var attrs: [Attr]
                if model.text.isEmpty {
                    attrs = [.foreground(.gray)]
                } else if normalCursor.selection > 0 && cOffset >= normalCursor.at
                    && cOffset < normalCursor.at + normalCursor.selection
                {
                    attrs = [.reverse]
                } else if cOffset == normalCursor.at && isResponder {
                    attrs = [.underline]
                } else {
                    attrs = extraAttrs
                }

                let printableChar: Character
                switch char {
                case "\n":
                    printableChar = " "
                case "󰀀":  // uF0000
                    printableChar = "´"
                    attrs.append(.reverse)
                case "󰀁":  // uF0001
                    printableChar = "ˆ"
                    attrs.append(.reverse)
                case "󰀂":  // uF0002
                    printableChar = "˜"
                    attrs.append(.reverse)
                case "󰀃":  // uF0003
                    printableChar = "¨"
                    attrs.append(.reverse)
                case "󰀄":  // uF0004
                    printableChar = "`"
                    attrs.append(.reverse)
                default:
                    printableChar = char
                }

                buffer.write(
                    AttributedCharacter(character: printableChar, attributes: attrs),
                    at: Point(x: xClip + xOffset, y: yClip + yOffset))

                if char == "\n" {
                    yOffset += 1
                    xOffset = 0
                } else {
                    xOffset += Buffer.displayWidth(of: char)
                }

                cOffset += 1
            }

            if isResponder && normalCursor.at == model.text.count {
                buffer.write(
                    AttributedCharacter(character: " ", attributes: [.underline]),
                    at: Point(x: xOffset + xClip, y: yOffset + yClip))
            }
            buffer.store(model)
        },
        events: { event, buffer in
            guard isResponder,
                case let .key(key) = event,
                let model: InputModel = buffer.retrieve()
            else { return ([], [event]) }
            let (nextModel, msgs, events): (InputModel, [Msg], [Event]) = model.keyEvent(
                key: key, onChange: onChange)
            buffer.store(nextModel)
            return (msgs, events)
        },
        debugName: "Input"
    )
}

extension InputModel {
    fileprivate func keyEvent<Msg>(key: KeyEvent, onChange: @escaping (String) -> Msg) -> (
        InputModel, [Msg], [Event]
    ) {
        let nextModel: InputModel
        let events: [Event]
        if key.isPrintable {
            (nextModel, events) = insert(string: key.toPrintable)
        } else if key == .enter, isMultiline {
            (nextModel, events) = insert(string: "\n")
        } else if key == .backspace {
            (nextModel, events) = backspace()
        } else if key == .signalEot {  // ctrl+d == delete
            (nextModel, events) = delete()
        } else if key == .left {
            (nextModel, events) = moveLeft()
        } else if key == .right {
            (nextModel, events) = moveRight()
        } else if key == .shift(.left) {
            (nextModel, events) = extendLeft()
        } else if key == .shift(.right) {
            (nextModel, events) = extendRight()
        } else if key == .up || key == .shift(.up) {
            (nextModel, events) = moveUp(extend: key == .shift(.up))
        } else if key == .down || key == .shift(.down) {
            (nextModel, events) = moveDown(extend: key == .shift(.down))
        } else if key == .ctrl(.a) {
            (nextModel, events) = moveToTop()
        } else if key == .ctrl(.e) {
            (nextModel, events) = moveToBottom()
        } else if key == .ctrl(.x) {
            (nextModel, events) = cut()
        } else if key == .ctrl(.c) {
            (nextModel, events) = copy()
        } else if key == .ctrl(.v) {
            (nextModel, events) = paste()
        } else if key == .home {
            (nextModel, events) = moveToBeginOfLine()
        } else if key == .end {
            (nextModel, events) = moveToEndOfLine()
        } else {
            return (self, [], [.key(key)])
        }

        let msgs: [Msg]
        if nextModel.text != text {
            msgs = [onChange(nextModel.text)]
        } else {
            msgs = []
        }
        return (nextModel, msgs, events)
    }

    fileprivate func insert(string insert: String) -> (InputModel, [Event]) {
        let offset = insert.reduce(0) { $0 + Buffer.displayWidth(of: $1) }
        if cursor.at == text.count && cursor.selection == 0 {
            let nextText = text + insert
            let (text, cursor) = fixDiacritics(
                nextText, cursor: TextCursor(at: self.cursor.at + offset, selection: 0))
            return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
        }

        let normalCursor = cursor.normalized
        // weird escape sequences can cause this:
        guard normalCursor.at < text.count else { return (self, []) }

        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let end = text.index(cursorStart, offsetBy: normalCursor.selection)
        let nextText = text.replacingCharacters(in: cursorStart..<end, with: insert)
        let (text, cursor) = fixDiacritics(
            nextText, cursor: TextCursor(at: normalCursor.at + offset, selection: 0))
        return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
    }

    fileprivate func backspace() -> (InputModel, [Event]) {
        guard cursor.at > 0 || cursor.selection > 0 else { return (self, []) }

        let normalCursor = cursor.normalized
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let range: Range<String.Index>
        let cursor: TextCursor
        if normalCursor.selection == 0 {
            let prev = text.index(cursorStart, offsetBy: -1)
            range = prev..<cursorStart
            cursor = TextCursor(at: normalCursor.at - 1, selection: 0)
        } else {
            let end = text.index(cursorStart, offsetBy: normalCursor.selection)
            range = cursorStart..<end
            cursor = TextCursor(at: normalCursor.at, selection: 0)
        }
        let nextText = text.replacingCharacters(in: range, with: "")
        let (text, nextCursor) = fixDiacritics(nextText, cursor: cursor)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func delete() -> (InputModel, [Event]) {
        if cursor.at == text.count && cursor.selection == 0 { return (self, []) }

        let normalCursor = cursor.normalized
        let cursorStart = text.index(text.startIndex, offsetBy: normalCursor.at)
        let range: Range<String.Index>
        let cursor: TextCursor
        if normalCursor.selection == 0 {
            let next = text.index(cursorStart, offsetBy: 1)
            range = cursorStart..<next
            cursor = TextCursor(at: normalCursor.at, selection: 0)
        } else {
            let end = text.index(cursorStart, offsetBy: normalCursor.selection)
            range = cursorStart..<end
            cursor = TextCursor(at: normalCursor.at, selection: 0)
        }
        let nextText = text.replacingCharacters(in: range, with: "")
        let (text, nextCursor) = fixDiacritics(nextText, cursor: cursor)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func moveLeft() -> (InputModel, [Event]) {
        let normalCursor = cursor.normalized
        let cursor: TextCursor
        if self.cursor.selection == 0 {
            cursor = TextCursor(at: max(self.cursor.at - 1, 0), selection: 0)
            return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
        } else {
            cursor = TextCursor(at: normalCursor.at, selection: 0)
            return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
        }
    }

    fileprivate func moveRight() -> (InputModel, [Event]) {
        let normalCursor = cursor.normalized
        let cursor: TextCursor
        if self.cursor.selection == 0 {
            let maxCursor = text.count
            cursor = TextCursor(at: min(self.cursor.at + 1, maxCursor), selection: 0)
            return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
        } else {
            cursor = TextCursor(at: normalCursor.at + normalCursor.selection, selection: 0)
            return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
        }
    }

    fileprivate func extendLeft() -> (InputModel, [Event]) {
        if cursor.at + cursor.selection == 0 { return (self, []) }
        let nextCursor = TextCursor(at: cursor.at, selection: cursor.selection - 1)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func extendRight() -> (InputModel, [Event]) {
        let maxCursor = text.count
        if cursor.at + cursor.selection == maxCursor { return (self, []) }
        let nextCursor = TextCursor(at: cursor.at, selection: cursor.selection + 1)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func moveUp(extend: Bool) -> (InputModel, [Event]) {
        let lines = text.lines
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
        let cursor: TextCursor
        if extend {
            if x == 0 {
                cursor = TextCursor(at: self.cursor.at, selection: extend ? -self.cursor.at : 0)
            } else {
                cursor = TextCursor(at: self.cursor.at, selection: x - self.cursor.at)
            }
        } else if x == 0 {
            cursor = TextCursor(at: 0, selection: 0)
        } else {
            cursor = TextCursor(at: x, selection: 0)
        }

        if prevCursor.at == cursor.at && prevCursor.selection == cursor.selection {
            return (self, [])
        }
        return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
    }

    fileprivate func moveDown(extend: Bool) -> (InputModel, [Event]) {
        let lines = text.lines
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
        let cursor: TextCursor
        if extend {
            if x > text.count {
                cursor = TextCursor(at: self.cursor.at, selection: text.count - self.cursor.at)
            } else {
                cursor = TextCursor(at: self.cursor.at, selection: x - self.cursor.at)
            }
        } else if x > text.count {
            cursor = TextCursor(at: text.count, selection: 0)
        } else {
            cursor = TextCursor(at: x, selection: 0)
        }

        if prevCursor.at == cursor.at && prevCursor.selection == cursor.selection {
            return (self, [])
        }
        return (InputModel(text: text, isMultiline: isMultiline, cursor: cursor), [.redraw])
    }

    fileprivate func moveToTop() -> (InputModel, [Event]) {
        guard cursor.at != 0 || cursor.selection != 0 else { return (self, []) }

        let nextCursor = TextCursor(at: 0, selection: 0)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func moveToBottom() -> (InputModel, [Event]) {
        guard cursor.at != text.count || cursor.selection != 0 else { return (self, []) }

        let nextCursor = TextCursor(at: text.count, selection: 0)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func cut() -> (InputModel, [Event]) {
        return self.copy().0.delete()
    }

    fileprivate func copy() -> (InputModel, [Event]) {
        let first = min(cursor.at, cursor.at + cursor.selection)
        let second = max(cursor.at, cursor.at + cursor.selection)
        let clipboard = String(
            text[
                text.index(
                    text.startIndex, offsetBy: first)..<text.index(
                        text.startIndex, offsetBy: second)
            ]
        )
        InputModel.clipboard = clipboard
        return (self, [])
    }

    fileprivate func paste() -> (InputModel, [Event]) {
        return self.insert(string: InputModel.clipboard)
    }

    fileprivate func moveToBeginOfLine() -> (InputModel, [Event]) {
        guard cursor.at != 0 || cursor.selection != 0 else { return (self, []) }

        let nextCursor = TextCursor(at: 0, selection: 0)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }

    fileprivate func moveToEndOfLine() -> (InputModel, [Event]) {
        guard cursor.at != text.count || cursor.selection != 0 else { return (self, []) }

        let nextCursor = TextCursor(at: text.count, selection: 0)
        return (InputModel(text: text, isMultiline: isMultiline, cursor: nextCursor), [.redraw])
    }
}

private func fixDiacritics(_ text: String, cursor: TextCursor) -> (String, TextCursor) {
    let newText =
        text
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
        return (
            newText,
            TextCursor(
                at: cursor.at - text.count + newText.count,
                selection: 0
            )
        )
    } else {
        return (text, cursor)
    }
}
