////
///  Mocks.swift
//

class MockProgram: Program {
    var mockModel: Any
    var component: Component?

    struct MockModel {}
    struct Quit {}
    struct Continue {}

    struct MockCommand {
        var result: Any?
    }

    convenience init() {
        self.init(model: MockModel())
    }

    init(model: Any) {
        self.mockModel = model
    }

    func model() -> Any {
        return mockModel
    }

    func update(model: inout Any, message: Any)
        -> (Any, [MockCommand], LoopState)
    {
        if message is Quit {
            return (mockModel, [], .quit)
        }
        return (mockModel, [], .continue)
    }

    func render(model: Any, in screenSize: Size) -> Component {
        if let component = component {
            self.component = nil

            return Window(components: [component, OnNext({ return Continue() })])
        }

        return OnNext({ return Quit() })

    }

    func start(command: MockCommand, done: @escaping (Any) -> Void) {
        if let result = command.result {
            done(result)
        }
    }

}

class MockScreen: ScreenType {
    var size: Size
    var events: [Event] = []
    var renderedComponent: Component?
    var renderedChars: Screen.Chars?
    var setupCalled = 0
    var teardownCalled = 0
    var resizedCalled = 0

    convenience init() {
        self.init(size: .zero)
    }

    init(size: Size) {
        self.size = size
    }

    func render(_ component: Component) -> Screen.Chars {
        renderedComponent = component
        let chars = component.chars(in: size)
        render(chars: chars)
        return chars
    }

    func render(chars: Screen.Chars) {
        self.renderedChars = chars
    }

    func setup() {
        setupCalled += 1
    }

    func teardown() {
        teardownCalled += 1
    }

    func nextEvent() -> Event? {
        guard events.count > 0 else { return nil }
        return events.removeFirst()
    }

    func resized(height: Int, width: Int) {
        resizedCalled += 1
        size = Size(width: width, height: height)
    }
}
