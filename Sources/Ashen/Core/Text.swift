////
///  Text.swift
//


public protocol AttrCharType {
    var char: String? { get }
    var attrs: [Attr] { get }
}

public protocol TextType {
    var chars: [AttrCharType] { get }
}

public struct AttrChar: AttrCharType {
    public var char: String?
    public var attrs: [Attr]

    public init(_ char: String?, _ attrs: [Attr] = []) {
        self.char = char
        self.attrs = attrs
    }

    public init(_ attrs: [Attr]) {
        self.char = nil
        self.attrs = attrs
    }

    public init(_ char: Character, _ attrs: [Attr] = []) {
        self.char = String(char)
        self.attrs = attrs
    }
}

extension AttrChar: TextType {
    public var chars: [AttrCharType] {
        return [self]
    }
}

public struct AttrText: TextType {
    public private(set) var chars: [AttrCharType]

    public init(_ content: [TextType]) {
        self.chars = content.flatMap { $0.chars }
    }

    public init(_ chars: [AttrChar] = []) {
        self.chars = chars
    }

    public init(_ chars: [AttrCharType] = []) {
        self.chars = chars
    }

    public mutating func append(_ text: TextType) {
        self.chars += text.chars
    }
}

public struct Text: TextType {
    public let text: String
    public let attrs: [Attr]

    public var chars: [AttrCharType] {
        return text.map { AttrChar($0, attrs) }
    }

    var description: String {
        return text
    }

    public init(_ text: String, _ attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: TextType {
    public var chars: [AttrCharType] {
        let text = self.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        return Array(text)
    }
}

extension Character: AttrCharType {
    public var char: String? { return String(self) }
    public var attrs: [Attr] { return [] }
}

public func + (lhs: AttrText, rhs: TextType) -> AttrText {
    return AttrText(lhs.chars + rhs.chars)
}

public func + (lhs: AttrText, rhs: AttrText) -> AttrText {
    return AttrText(lhs.chars + rhs.chars)
}

public func + (lhs: TextType, rhs: TextType) -> TextType {
    return AttrText(lhs.chars + rhs.chars)
}
