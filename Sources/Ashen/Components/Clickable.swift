////
///  Clickable.swift
//


/// Usage:
///     Clickable(ComponentView, { Message })
/// The ComponentView will determine the location and size, the rest will
/// be sized and positioned the same way.  This is a great way to create a
/// clickable area, e.g. `Clickable(Box(...), Button(onClick: { }))`
public class Clickable: ComponentLayout {
    let view: ComponentView
    let button: Button

    public init(_ view: ComponentView, _ onClick: @escaping SimpleHandler) {
        self.view = view
        self.button = Button(onClick: onClick)
        super.init()
        self.components = [view, button]
        self.location = view.location
    }

    override public func desiredSize() -> DesiredSize {
        view.desiredSize()
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        view.render(to: buffer, in: rect)
        button.render(to: buffer, in: rect)
    }
}
