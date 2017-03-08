////
///  SpecsScreen.swift
//

class SpecsScreen: ScreenType {
    var size: Size = Size.max
    var buffer: Buffer?

    func render(_ component: Component) -> Buffer {
        let buffer = component.render(size: size)
        render(buffer: buffer)
        return buffer
    }

    func render(buffer: Buffer) {
        self.buffer = buffer
    }

    func setup() {
    }

    func teardown() {
        guard let buffer = buffer else { return }
        let output = SpecsProgram.toString(buffer)
        print(output)
    }

    func nextEvent() -> Event? {
        return nil
    }

    func resized(height: Int, width: Int) {
        size = Size(width: width, height: height)
    }

}
