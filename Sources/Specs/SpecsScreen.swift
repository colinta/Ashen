////
///  SpecsScreen.swift
//

class SpecsScreen: ScreenType {
    var size: Size = Size.max
    var chars: Screen.Chars?

    func render(_ component: ComponentType) -> Screen.Chars {
        let chars = component.chars(in: size)
        render(chars: chars)
        return chars
    }

    func render(chars: Screen.Chars) {
        self.chars = chars
    }

    func setup() {
    }

    func teardown() {
        guard let chars = chars else { return }
        let output = Specs.toString(chars)
        print(output)
    }

    func nextEvent() -> Event? {
        return nil
    }

    func resized(height: Int, width: Int) {
        size = Size(width: width, height: height)
    }

}
