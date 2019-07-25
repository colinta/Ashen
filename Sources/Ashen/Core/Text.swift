////
///  Text.swift
//


public protocol AttrCharType {
    var string: String? { get }
    var attrs: [Attr] { get }
}

public protocol TextType {
    var chars: [AttrCharType] { get }
}

public struct AttrChar: AttrCharType {
    public var string: String?
    public var attrs: [Attr]

    init(_ string: String?, _ attrs: [Attr] = []) {
        self.string = string
        self.attrs = attrs
    }

    init(_ char: Character, _ attrs: [Attr] = []) {
        self.string = String(char)
        self.attrs = attrs
    }
}

public struct AttrText: TextType {
    private(set) var content: [TextType]

    public var chars: [AttrCharType] {
        return content.flatMap { $0.chars }
    }

    public init(_ content: [TextType] = []) {
        self.content = content
    }

    public mutating func append(_ text: TextType) {
        self.content.append(text)
    }
}

public struct Text: TextType {
    public let text: String?
    public let attrs: [Attr]

    public var chars: [AttrCharType] {
        guard let text = text else { return [AttrChar(nil, attrs)] }
        return text.map { AttrChar($0, attrs) }
    }

    var description: String {
        return text ?? ""
    }

    public init(_ text: String?, attrs: [Attr] = []) {
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
    public var string: String? { return String(self) }
    public var attrs: [Attr] { return [] }
}

public func + (lhs: AttrText, rhs: TextType) -> AttrText {
    return AttrText(lhs.content + [rhs])
}

public func + (lhs: AttrText, rhs: AttrText) -> AttrText {
    return AttrText(lhs.content + rhs.content)
}

public func + (lhs: TextType, rhs: TextType) -> TextType {
    return AttrText([lhs, rhs])
}
