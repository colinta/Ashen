////
///  Text.swift
//


protocol TextType {
    var text: String? { get }
    var attrs: [Attr] { get }
}

struct Text: TextType {
    let text: String?
    let attrs: [Attr]

    init(_ text: String?, attrs: [Attr] = []) {
        self.text = text
        self.attrs = attrs
    }
}

extension String: TextType {
    var text: String? { return self }
    var attrs: [Attr] { return [] }
}
