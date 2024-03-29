////
///  AttributedText.swift
//

public struct AttributedCharacter: Equatable {
    public let character: Character
    public let attributes: [Attr]

    public init(character: Character, attributes: [Attr]) {
        self.character = character
        self.attributes = attributes
    }

    public func has(attr: Attr) -> Bool {
        attributes.contains(attr)
    }

    public func styled(_ attr: Attr) -> AttributedCharacter {
        if attributes.contains(attr) {
            return self
        } else {
            let attributes: [Attr]
            if case .foreground = attr {
                attributes = self.attributes.filter { attr in
                    guard case .foreground = attr else { return true }
                    return false
                }
            } else if case .background = attr {
                attributes = self.attributes.filter { attr in
                    guard case .background = attr else { return true }
                    return false
                }
            } else {
                attributes = self.attributes
            }
            return AttributedCharacter(
                character: self.character, attributes: attributes + [attr])
        }
    }

    public func styled(_ attrs: [Attr]) -> AttributedCharacter {
        attrs.reduce(self) { $0.styled($1) }
    }

    public func reset() -> AttributedCharacter {
        AttributedCharacter(character: self.character, attributes: [])
    }

    public static func == (lhs: AttributedCharacter, rhs: AttributedCharacter) -> Bool {
        return lhs.character == rhs.character && lhs.attributes == rhs.attributes
    }

    public static let skip = AttributedCharacter(character: "\u{FEFF}", attributes: [])
    public static let null = AttributedCharacter(character: "\u{0}", attributes: [])
}

public protocol Attributed {
    var attributedCharacters: [AttributedCharacter] { get }
    var countLines: Int { get }
    var maxWidth: Int { get }
}

extension AttributedCharacter: Attributed {
    public var attributedCharacters: [AttributedCharacter] { [self] }
    public var countLines: Int {
        guard self.character != "\n" else {
            return 2
        }
        return 1
    }
    public var maxWidth: Int {
        guard self.character != "\n" else {
            return 0
        }
        return Buffer.displayWidth(of: self.character)
    }
}

extension Attributed {
    public func styled(_ attr: Attr) -> AttributedString {
        AttributedString(
            characters: self.attributedCharacters.map { $0.styled(attr) })
    }

    public func styled(_ attrs: [Attr]) -> AttributedString {
        attrs.reduce(self.styled(.none)) { $0.styled($1) }
    }

    public func underlined() -> AttributedString {
        styled(.underline)
    }

    public func reversed() -> AttributedString {
        styled(.reverse)
    }

    public func bold() -> AttributedString {
        styled(.bold)
    }

    public func foreground(_ color: Color) -> AttributedString {
        styled(.foreground(color))
    }

    public func background(_ color: Color) -> AttributedString {
        styled(.background(color))
    }

    public func reset() -> AttributedString {
        AttributedString(
            characters: self.attributedCharacters.map { $0.reset() })
    }

    public func insertNewlines(fitting: Int) -> AttributedString {
        var current = AttributedString()
        var buffer = AttributedString()
        var lineWidth = 0
        var wordWidth = 0
        var shouldAddNewline = false
        var shouldSkipSpaces = false
        for ac in self.attributedCharacters {
            var characterWidth: Int { Buffer.displayWidth(of: ac.character) }

            if ac.character == "\n" {
                current = current + buffer + AttributedString("\n")
                buffer = AttributedString("")
                lineWidth = 0
                wordWidth = 0
                shouldAddNewline = false
                shouldSkipSpaces = false
            } else if ac.character == " ", buffer.attributedCharacters.isEmpty, !shouldSkipSpaces {
                current = current + ac
                lineWidth += characterWidth
            } else if ac.character == " " {
                if wordWidth > 0 {
                    current = current + buffer
                    lineWidth += wordWidth
                    buffer = AttributedString("")
                    wordWidth = 0
                }

                if lineWidth + characterWidth > fitting {
                    current = current + AttributedString("\n", attributes: ac.attributes)
                    lineWidth = 0
                    shouldSkipSpaces = true
                } else if !shouldSkipSpaces {
                    current = current + ac
                    lineWidth += characterWidth
                }
            } else {
                if lineWidth + wordWidth + characterWidth > fitting {
                    if lineWidth == 0 {
                        current = current + buffer
                        buffer = AttributedString("")
                    }
                    current = current + AttributedString("\n", attributes: ac.attributes)
                    lineWidth = 0
                    shouldSkipSpaces = true
                } else {
                    shouldSkipSpaces = false
                }

                buffer = buffer + ac
                wordWidth += characterWidth
            }
        }

        if shouldAddNewline {
            current = current + AttributedString("\n")
        }
        return current + buffer
    }

    public var string: String {
        attributedCharacters.reduce("") { str, c in
            "\(str)\(c.character)"
        }
    }
}

public struct AttributedString: Attributed {
    public let attributedCharacters: [AttributedCharacter]
    public var count: Int { attributedCharacters.count }
    public var isEmpty: Bool { count == 0 }
    public var countLines: Int {
        self.attributedCharacters.reduce(1) { memo, ac in
            if ac.character == "\n" {
                return memo + 1
            } else {
                return memo
            }
        }
    }
    public var maxWidth: Int {
        let (maxWidth, currentWidth) = self.attributedCharacters.reduce((max: 0, current: 0)) {
            memo, ac in
            let (maxWidth, currentWidth) = memo
            if ac.character == "\n" {
                return (max(maxWidth, currentWidth), 0)
            } else {
                return (maxWidth, currentWidth + Buffer.displayWidth(of: ac.character))
            }
        }
        return max(maxWidth, currentWidth)
    }

    public init(_ string: String = "", attributes: [Attr] = []) {
        self.attributedCharacters = string.map {
            AttributedCharacter(character: $0, attributes: attributes)
        }
    }

    public init(_ char: AttributedCharacter) {
        self.attributedCharacters = [char]
    }

    public init(characters: [AttributedCharacter]) {
        self.attributedCharacters = characters
    }

    public func join(_ join: [AttributedString]) -> AttributedString {
        AttributedString(characters: self.attributedCharacters + join.attributedCharacters)
    }

    public static func + (lhs: AttributedString, rhs: AttributedString) -> AttributedString {
        AttributedString(characters: lhs.attributedCharacters + rhs.attributedCharacters)
    }

    public static func + (lhs: AttributedString, rhs: AttributedCharacter) -> AttributedString {
        AttributedString(characters: lhs.attributedCharacters + [rhs])
    }

    public static func + (lhs: String, rhs: AttributedString) -> AttributedString {
        AttributedString(characters: lhs.attributedCharacters + rhs.attributedCharacters)
    }

    public static func + (lhs: AttributedString, rhs: String) -> AttributedString {
        AttributedString(characters: lhs.attributedCharacters + rhs.attributedCharacters)
    }
}
