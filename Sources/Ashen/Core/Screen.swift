////
///  ScreenType.swift
//


protocol ScreenType {
    var size: Size { get }
    func render(_: Component) -> Buffer
    func render(buffer _: Buffer)
    func setup() throws
    func teardown()
    func nextEvent() -> Event?
}
