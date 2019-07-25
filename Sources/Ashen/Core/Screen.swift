////
///  ScreenType.swift
//


public protocol ScreenType {
    var size: Size { get }
    func render(window: Component) -> Buffer
    func render(buffer _: Buffer)
    func setup() throws
    func teardown()
    func nextEvent() -> Event?
}

public extension ScreenType {
    func setup() throws {}
}
