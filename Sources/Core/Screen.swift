////
///  ScreenType.swift
//


protocol ScreenType {
    var size: Size { get }
    func render(_: Component) -> Buffer
    func render(buffer _: Buffer)
    func setup()
    func teardown()
    func nextEvent() -> Event?
    func initColor(_: Int, fg: (Int, Int, Int)?, bg: (Int, Int, Int)?)
}
