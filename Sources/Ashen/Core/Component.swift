////
///  Component.swift
//


public class Component: Equatable {
    var id: String = ""

    func messages(for _: Event) -> [AnyMessage] {
        return []
    }

    func render(size: Size) -> Buffer {
        let buffer = Buffer(size: size)
        render(to: buffer, in: Rect(size: size))
        return buffer
    }

    func render(to _: Buffer, in _: Rect) {
    }

    public func map<T, U>(_: @escaping (T) -> U) -> Self {
        return self
    }

    func merge(with _: Component) {
    }

    public static func == (lhs: Component, rhs: Component) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.id == rhs.id
    }
}

public class ComponentView: Component {
    var location: Location = .topLeft()
    func desiredSize() -> DesiredSize {
        return DesiredSize()
    }
}

public class ComponentLayout: ComponentView {
    var components: [Component] = []
    var views: [ComponentView] { return components.compactMap { $0 as? ComponentView } }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let window = self
        window.components = components.map { comp in
            return comp.map(mapper)
        }
        return window
    }

    override func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .key(key):
            var keyboardHandled = false
            var messages: [AnyMessage] = []
            for component in components {
                if let keyboardComponent = component as? KeyboardTrapComponent {
                    if !keyboardHandled && keyboardComponent.shouldAccept(key: key) {
                        messages += component.messages(for: event)
                        keyboardHandled = true
                    }
                }
                else {
                    messages += component.messages(for: event)
                }
            }
            return messages
        default:
            break
        }
        return components.flatMap { $0.messages(for: event) }
    }

    override func render(to buffer: Buffer, in rect: Rect) {
        Window.render(views: views, to: buffer, in: rect)
    }

    override func merge(with prevComponent: Component) {
        guard let prevWindow = prevComponent as? ComponentLayout else { return }

        var windowIndex = 0
        let prevComponents = prevWindow.components
        for component in components {
            guard windowIndex < prevComponents.count else { break }

            if component != prevComponents[windowIndex] {
                let restoreIndex = windowIndex
                while component != prevComponents[windowIndex] {
                    windowIndex += 1
                    guard windowIndex < prevComponents.count else {
                        windowIndex = restoreIndex
                        break
                    }
                }
            }

            guard windowIndex < prevComponents.count else { break }
            let prev = prevComponents[windowIndex]
            if component == prev {
                component.merge(with: prev)
                windowIndex += 1
            }
        }
        return
    }

}

protocol KeyboardTrapComponent {
    func shouldAccept(key: KeyEvent) -> Bool
}
