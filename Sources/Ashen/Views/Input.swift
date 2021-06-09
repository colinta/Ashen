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
                case "\u{F0000}":  // combining ´
                    printableChar = "´"
                    attrs.append(.reverse)
                case "\u{F0001}":  // combining ˆ
                    printableChar = "ˆ"
                    attrs.append(.reverse)
                case "\u{F0002}":  // combining ˜
                    printableChar = "˜"
                    attrs.append(.reverse)
                case "\u{F0003}":  // combining ¨
                    printableChar = "¨"
                    attrs.append(.reverse)
                case "\u{F0004}":  // combining `
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
        .replacingOccurrences(of: "\u{F0000}A", with: "Á")
        .replacingOccurrences(of: "\u{F0000}E", with: "É")
        .replacingOccurrences(of: "\u{F0000}I", with: "Í")
        .replacingOccurrences(of: "\u{F0000}O", with: "Ó")
        .replacingOccurrences(of: "\u{F0000}U", with: "Ú")
        .replacingOccurrences(of: "\u{F0000}Y", with: "Ý")
        .replacingOccurrences(of: "\u{F0000}a", with: "á")
        .replacingOccurrences(of: "\u{F0000}e", with: "é")
        .replacingOccurrences(of: "\u{F0000}i", with: "í")
        .replacingOccurrences(of: "\u{F0000}o", with: "ó")
        .replacingOccurrences(of: "\u{F0000}u", with: "ú")
        .replacingOccurrences(of: "\u{F0000}y", with: "ý")
        .replacingOccurrences(of: "\u{F0000}C", with: "Ć")
        .replacingOccurrences(of: "\u{F0000}c", with: "ć")
        .replacingOccurrences(of: "\u{F0000}L", with: "Ĺ")
        .replacingOccurrences(of: "\u{F0000}l", with: "ĺ")
        .replacingOccurrences(of: "\u{F0000}N", with: "Ń")
        .replacingOccurrences(of: "\u{F0000}n", with: "ń")
        .replacingOccurrences(of: "\u{F0000}R", with: "Ŕ")
        .replacingOccurrences(of: "\u{F0000}r", with: "ŕ")
        .replacingOccurrences(of: "\u{F0000}S", with: "Ś")
        .replacingOccurrences(of: "\u{F0000}s", with: "ś")
        .replacingOccurrences(of: "\u{F0000}Z", with: "Ź")
        .replacingOccurrences(of: "\u{F0000}z", with: "ź")
        .replacingOccurrences(of: "\u{F0000}G", with: "Ǵ")
        .replacingOccurrences(of: "\u{F0000}g", with: "ǵ")
        .replacingOccurrences(of: "\u{F0000}Æ", with: "Ǽ")
        .replacingOccurrences(of: "\u{F0000}æ", with: "ǽ")
        .replacingOccurrences(of: "\u{F0000}K", with: "Ḱ")
        .replacingOccurrences(of: "\u{F0000}k", with: "ḱ")
        .replacingOccurrences(of: "\u{F0000}M", with: "Ḿ")
        .replacingOccurrences(of: "\u{F0000}m", with: "ḿ")
        .replacingOccurrences(of: "\u{F0000}P", with: "Ṕ")
        .replacingOccurrences(of: "\u{F0000}p", with: "ṕ")
        .replacingOccurrences(of: "\u{F0000}W", with: "Ẃ")
        .replacingOccurrences(of: "\u{F0000}w", with: "ẃ")
        // ˆ âêîôû
        .replacingOccurrences(of: "\u{F0001}A", with: "Â")
        .replacingOccurrences(of: "\u{F0001}E", with: "Ê")
        .replacingOccurrences(of: "\u{F0001}I", with: "Î")
        .replacingOccurrences(of: "\u{F0001}O", with: "Ô")
        .replacingOccurrences(of: "\u{F0001}U", with: "Û")
        .replacingOccurrences(of: "\u{F0001}a", with: "â")
        .replacingOccurrences(of: "\u{F0001}e", with: "ê")
        .replacingOccurrences(of: "\u{F0001}i", with: "î")
        .replacingOccurrences(of: "\u{F0001}o", with: "ô")
        .replacingOccurrences(of: "\u{F0001}u", with: "û")
        .replacingOccurrences(of: "\u{F0001}C", with: "Ĉ")
        .replacingOccurrences(of: "\u{F0001}c", with: "ĉ")
        .replacingOccurrences(of: "\u{F0001}G", with: "Ĝ")
        .replacingOccurrences(of: "\u{F0001}g", with: "ĝ")
        .replacingOccurrences(of: "\u{F0001}H", with: "Ĥ")
        .replacingOccurrences(of: "\u{F0001}h", with: "ĥ")
        .replacingOccurrences(of: "\u{F0001}J", with: "Ĵ")
        .replacingOccurrences(of: "\u{F0001}j", with: "ĵ")
        .replacingOccurrences(of: "\u{F0001}S", with: "Ŝ")
        .replacingOccurrences(of: "\u{F0001}s", with: "ŝ")
        .replacingOccurrences(of: "\u{F0001}W", with: "Ŵ")
        .replacingOccurrences(of: "\u{F0001}w", with: "ŵ")
        .replacingOccurrences(of: "\u{F0001}Y", with: "Ŷ")
        .replacingOccurrences(of: "\u{F0001}y", with: "ŷ")
        // ˜ ñãõ
        .replacingOccurrences(of: "\u{F0002}A", with: "Ã")
        .replacingOccurrences(of: "\u{F0002}N", with: "Ñ")
        .replacingOccurrences(of: "\u{F0002}O", with: "Õ")
        .replacingOccurrences(of: "\u{F0002}a", with: "ã")
        .replacingOccurrences(of: "\u{F0002}n", with: "ñ")
        .replacingOccurrences(of: "\u{F0002}o", with: "õ")
        .replacingOccurrences(of: "\u{F0002}I", with: "Ĩ")
        .replacingOccurrences(of: "\u{F0002}i", with: "ĩ")
        .replacingOccurrences(of: "\u{F0002}U", with: "Ũ")
        .replacingOccurrences(of: "\u{F0002}u", with: "ũ")
        // ¨ äëïöü
        .replacingOccurrences(of: "\u{F0003}A", with: "Ä")
        .replacingOccurrences(of: "\u{F0003}E", with: "Ë")
        .replacingOccurrences(of: "\u{F0003}I", with: "Ï")
        .replacingOccurrences(of: "\u{F0003}O", with: "Ö")
        .replacingOccurrences(of: "\u{F0003}U", with: "Ü")
        .replacingOccurrences(of: "\u{F0003}a", with: "ä")
        .replacingOccurrences(of: "\u{F0003}e", with: "ë")
        .replacingOccurrences(of: "\u{F0003}i", with: "ï")
        .replacingOccurrences(of: "\u{F0003}o", with: "ö")
        .replacingOccurrences(of: "\u{F0003}u", with: "ü")
        .replacingOccurrences(of: "\u{F0003}Y", with: "Ÿ")
        .replacingOccurrences(of: "\u{F0003}y", with: "ÿ")
        .replacingOccurrences(of: "\u{F0003}W", with: "Ẅ")
        .replacingOccurrences(of: "\u{F0003}w", with: "ẅ")
        .replacingOccurrences(of: "\u{F0003}X", with: "Ẍ")
        .replacingOccurrences(of: "\u{F0003}x", with: "ẍ")
        .replacingOccurrences(of: "\u{F0003}t", with: "ẗ")
        .replacingOccurrences(of: "\u{F0003}H", with: "Ḧ")
        .replacingOccurrences(of: "\u{F0003}h", with: "ḧ")
        .replacingOccurrences(of: "\u{F0003}3", with: "Ӟ")
        // ` àèìòù
        .replacingOccurrences(of: "\u{F0004}A", with: "À")
        .replacingOccurrences(of: "\u{F0004}E", with: "È")
        .replacingOccurrences(of: "\u{F0004}I", with: "Ì")
        .replacingOccurrences(of: "\u{F0004}O", with: "Ò")
        .replacingOccurrences(of: "\u{F0004}U", with: "Ù")
        .replacingOccurrences(of: "\u{F0004}a", with: "à")
        .replacingOccurrences(of: "\u{F0004}e", with: "è")
        .replacingOccurrences(of: "\u{F0004}i", with: "ì")
        .replacingOccurrences(of: "\u{F0004}o", with: "ò")
        .replacingOccurrences(of: "\u{F0004}u", with: "ù")
        .replacingOccurrences(of: "\u{F0004}N", with: "Ǹ")
        .replacingOccurrences(of: "\u{F0004}n", with: "ǹ")
        .replacingOccurrences(of: "\u{F0004}W", with: "Ẁ")
        .replacingOccurrences(of: "\u{F0004}w", with: "ẁ")
        .replacingOccurrences(of: "\u{F0004}Y", with: "Ỳ")
        .replacingOccurrences(of: "\u{F0004}y", with: "ỳ")
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
