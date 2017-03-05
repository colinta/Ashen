////
///  Component.swift
//


class Component: Equatable {
    var id: String = ""

    func messages(for _: Event) -> [AnyMessage] {
        return []
    }

    func chars(in _: Size) -> Screen.Chars {
        return [:]
    }

    func map<T, U>(_: @escaping (T) -> U) -> Self {
        return self
    }

    func merge(with _: Component) {
    }

    static func == (lhs: Component, rhs: Component) -> Bool {
        return type(of: lhs) == type(of: rhs) && lhs.id == rhs.id
    }
}

class ComponentView: Component {
    var location: Location = .topLeft()
    func desiredSize() -> DesiredSize {
        return DesiredSize()
    }
}

class ComponentLayout: ComponentView {
    var components: [Component] = []

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
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
            for component in components.reversed() {
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

    override func chars(in screenSize: Size) -> Screen.Chars {
        return Window.chars(components: components, in: screenSize)
    }

    override func merge(with prevComponent: Component) {
        guard let prevWindow = prevComponent as? ComponentLayout else { return }

        var windowIndex = 0
        let prevComponents = prevWindow.components
        for component in components {
            guard windowIndex < prevComponents.count else { break }

            if windowIndex < prevComponents.count &&
                component != prevComponents[windowIndex]
            {
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
