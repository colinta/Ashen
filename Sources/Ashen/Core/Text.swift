////
///  Text.swift
//


protocol AttrCharType {
    var string: String? { get }
    var attrs: [Attr] { get }
}

protocol TextType {
    var chars: [AttrCharType] { get }
}

struct AttrChar: AttrCharType {
    var string: String?
    var attrs: [Attr]

    init(_ string: String?, _ attrs: [Attr] = []) {
        self.string = string
        self.attrs = attrs
    }

    init(_ char: Character, _ attrs: [Attr] = []) {
        self.string = String(char)
        self.attrs = attrs
    }
}

struct AttrText: TextType {
    private(set) var content: [TextType]

    var chars: [AttrCharType] {
        return content.flatMap { $0.chars }
    }

    init(_ content: [TextType] = []) {
        self.content = content
    }

    mutating func append(_ text: TextType) {
        self.content.append(text)
    }
}

struct Text: TextType {
    let text: String?
    let attrs: [Attr]

    var chars: [AttrCharType] {
        guard let text = text else { return [AttrChar(nil, attrs)] }
        return text.map { AttrChar($0, attrs) }
    }

    var description: String {
        return text ?? ""
    }

    init(_ text: String?, attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: TextType {
    var chars: [AttrCharType] {
        let text = self.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        return Array(text)
    }
}

extension Character: AttrCharType {
    var string: String? { return String(self) }
    var attrs: [Attr] { return [] }
}

func + (lhs: AttrText, rhs: TextType) -> AttrText {
    return AttrText(lhs.content + [rhs])
}

func + (lhs: AttrText, rhs: AttrText) -> AttrText {
    return AttrText(lhs.content + rhs.content)
}

func + (lhs: TextType, rhs: TextType) -> TextType {
    return AttrText([lhs, rhs])
}
