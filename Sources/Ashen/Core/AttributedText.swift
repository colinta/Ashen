////
///  AttributedText.swift
//

public struct AttributedCharacter: Equatable {
    let character: Character
    let attributes: [Attr]

    public func styled(_ attr: Attr) -> AttributedCharacter {
        if attributes.contains(attr) {
            return self
        } else {
            return AttributedCharacter(
                character: self.character, attributes: self.attributes + [attr])
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
}

public protocol Attributed {
    var attributedCharacters: [AttributedCharacter] { get }
    var countLines: Int { get }
    var maxWidth: Int { get }
}

extension Attributed {
    public func styled(_ attr: Attr) -> AttributedString {
        AttributedString(
            characters: self.attributedCharacters.map { $0.styled(attr) })
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
}

public struct AttributedString: Attributed {
    public let attributedCharacters: [AttributedCharacter]
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
                return (maxWidth, currentWidth + 1)
            }
        }
        return max(maxWidth, currentWidth)
    }

    public init(_ string: String, attributes: [Attr] = []) {
        self.attributedCharacters = string.map {
            AttributedCharacter(character: $0, attributes: attributes)
        }
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

    public static func + (lhs: String, rhs: AttributedString) -> AttributedString {
        AttributedString(characters: lhs.attributedCharacters + rhs.attributedCharacters)
    }

    public static func + (lhs: AttributedString, rhs: String) -> AttributedString {
        AttributedString(characters: lhs.attributedCharacters + rhs.attributedCharacters)
    }
}

extension String: Attributed {
    public var attributedCharacters: [AttributedCharacter] {
        self.map { AttributedCharacter(character: $0, attributes: []) }
    }
}

extension Array: Attributed where Element: Attributed {
    public var attributedCharacters: [AttributedCharacter] {
        self.flatMap { str in str.attributedCharacters }
    }
    public var countLines: Int {
        AttributedString(characters: attributedCharacters).countLines
    }
    public var maxWidth: Int {
        AttributedString(characters: attributedCharacters).maxWidth
    }
}
