////
///  SpecsScreen.swift
//

class SpecsScreen: ScreenType {
    var size: Size = Size.max
    var buffer: Buffer?

    func render(window: Component) -> Buffer {
        let buffer = window.render(size: size)
        render(buffer: buffer)
        return buffer
    }

    func render(buffer: Buffer) {
        self.buffer = buffer
    }

    func setup() throws {
    }

    func teardown() {
        guard let buffer = buffer else { return }
        let output = SpecsProgram.toString(buffer)
        print(output)
    }

    func nextEvent() -> Event? {
        return nil
    }

}
