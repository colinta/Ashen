////
///  FlowLayout.swift
//


class FlowLayout: ComponentLayoutType {
    enum Orientation {
        case vertical
        case horizontal
    }

    static func horizontal(components: [ComponentType]) {
        return FlowLayout(.horizontal, components: components)
    }

    static func vertical(components: [ComponentType]) {
        return FlowLayout(.vertical, components: components)
    }

    let components: [ComponentType]

    init(_ orientation: Orientation, components: [ComponentType]) {

        switch orientation {
        case .horizontal:
            self.components = horizontalLayout(components)
        case .vertical:
            self.components = verticalLayout(components)
        }
    }

    func horizontalLayout(components: [ComponentType]) -> [ComponentType] {
        var x = 0
    }

    func verticalLayout(components: [ComponentType]) -> [ComponentType] {

    }

}
