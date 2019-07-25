////
///  Mocks.swift
//

struct MockProgram: Program {
    var mockModel: Any
    var component: Component?

    struct MockModel {}
    struct Quit {}
    struct Continue {}

    init() {
        self.init(model: MockModel())
    }

    init(model: Any) {
        self.mockModel = model
    }

    func initial() -> (Any, [Command]) {
        return (mockModel, [])
    }

    func update(model: inout Any, message: Any)
        -> (Any, [Command], LoopState)
    {
        if message is Quit {
            return (mockModel, [], .quit)
        }
        return (mockModel, [], .continue)
    }

    func render(model: Any, in size: Size) -> Component {
        if let component = component {
            return Window(components: [component, OnNext({ return Continue() })])
        }

        return OnNext({ return Quit() })

    }
}

class MockScreen: ScreenType {
    var size: Size
    var events: [Event] = []
    var renderedWindow: Window?
    var renderedBuffer: Buffer?
    var setupCalled = 0
    var teardownCalled = 0

    convenience init() {
        self.init(size: .zero)
    }

    init(size: Size) {
        self.size = size
    }

    func render(window: Component) -> Buffer {
        renderedWindow = window
        let buffer = window.render(size: size)
        render(buffer: buffer)
        return buffer
    }

    func render(buffer: Buffer) {
        self.renderedBuffer = buffer
    }

    func setup() throws {
        setupCalled += 1
    }

    func teardown() {
        teardownCalled += 1
    }

    func nextEvent() -> Event? {
        guard events.count > 0 else { return nil }
        return events.removeFirst()
    }
}
