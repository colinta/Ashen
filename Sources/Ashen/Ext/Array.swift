////
///  Array.swift
//

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
