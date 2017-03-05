////
///  FlowLayout.swift
//


class FlowLayout: ComponentLayout {
    enum Orientation {
        case vertical
        case horizontal
    }

    static func horizontal(components: [Component]) {
        return FlowLayout(.horizontal, components: components)
    }

    static func vertical(components: [Component]) {
        return FlowLayout(.vertical, components: components)
    }

    let components: [Component]

    init(_ orientation: Orientation, components: [Component]) {

        switch orientation {
        case .horizontal:
            self.components = horizontalLayout(components)
        case .vertical:
            self.components = verticalLayout(components)
        }
    }

    func horizontalLayout(components: [Component]) -> [Component] {
        var x = 0
    }

    func verticalLayout(components: [Component]) -> [Component] {

    }

}
