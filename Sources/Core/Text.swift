////
///  Text.swift
//


protocol TextType {
    var chars: [AttrChar] { get }
}

struct AttrChar: TextType {
    var string: String?
    var attrs: [Attr]
    var chars: [AttrChar] { return [self] }

    init(_ string: String?, _ attrs: [Attr] = []) {
        self.string = string
        self.attrs = attrs
    }

    init(_ string: Character, _ attrs: [Attr] = []) {
        self.string = String(string)
        self.attrs = attrs
    }
}

struct AttrText: TextType {
    private(set) var content: [TextType]

    var chars: [AttrChar] {
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

    var chars: [AttrChar] {
        guard let text = text else { return [AttrChar(nil, attrs)] }
        return text.characters.map { AttrChar($0, attrs) }
    }

    init(_ text: String?, attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: TextType {
    var chars: [AttrChar] {
        let text = self.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        return text.characters.map { AttrChar($0, []) }
    }
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
