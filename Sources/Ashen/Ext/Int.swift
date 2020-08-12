////
///  Int.swift
//

extension Int: Attributed {
    public var attributedCharacters: [AttributedCharacter] {
        self.description.attributedCharacters
    }
    public var countLines: Int {
        1
    }
    public var maxWidth: Int {
        self.description.count
    }
}
