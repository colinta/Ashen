////
///  Chars.swift
//

class Chars {
    typealias Buffer
    private var buffer: Buffer = [:]

    func write(_ text: TextType, x: Int, y: Int) {
        var row = buffer[y] ?? [:]
        row[x] = text
        buffer[y] = row
    }

    func chars() -> Buffer {
        return buffer
    }
}
