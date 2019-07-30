////
///  Component.swift
//


public class Component: Equatable {
    var id: String?

    open func messages(for _: Event) -> [AnyMessage] {
        return []
    }

    open func render(size: Size) -> Buffer {
        let buffer = Buffer(size: size)
        render(to: buffer, in: Rect(size: size))
        return buffer
    }

    open func render(to _: Buffer, in _: Rect) {
    }

    open func map<T, U>(_: @escaping (T) -> U) -> Self {
        return self
    }

    open func merge(with _: Component) {
    }

    // used by ComponentLayout.messages to determine if a keyboard or mouse
    // event has been handled and should not be handed to other Components
    open func shouldStopProcessing(event: Event) -> Bool {
        return false
    }

    public static func == (lhs: Component, rhs: Component) -> Bool {
        guard type(of: lhs) == type(of: rhs) else { return false }
        guard
            let lhsId = lhs.id,
            let rhsId = rhs.id
        else {
            return lhs.id == nil && rhs.id == nil
        }
        return lhsId == rhsId
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

    override public func messages(for event: Event) -> [AnyMessage] {
        var messages: [AnyMessage] = []
        for component in components {
            messages += component.messages(for: event)
            if component.shouldStopProcessing(event: event) {
                break
            }
        }
        return messages
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        Window.render(views: views, to: buffer, in: rect)
    }

    override public func shouldStopProcessing(event: Event) -> Bool {
        return components.firstIndex { $0.shouldStopProcessing(event: event) } != nil
    }

    /// Merge this Layout and its components.  The algorithm works like this:
    /// - prevIndex starts at 0
    /// - scan through the current components
    /// - if the component doesn't match the previous component at index
    ///   prevIndex, scan through the remaining prevLayout components, looking
    ///   for a match:
    ///     - if a match is found, the prevIndex points to it; the components
    ///       that were scanned to that point are considered deleted
    ///     - if no match is found, restore the prevIndex; the new component is
    ///       considered inserted, and not merged
    /// - if the component matches the prev component at prevIndex, merge them.
    override public func merge(with prevComponent: Component) {
        guard let prevLayout = prevComponent as? ComponentLayout else { return }

        var prevIndex = 0
        let prevComponents = prevLayout.components
        for component in components {
            guard prevIndex < prevComponents.count else { break }

            if component != prevComponents[prevIndex] {
                let restoreIndex = prevIndex
                while component != prevComponents[prevIndex] {
                    prevIndex += 1
                    if prevIndex == prevComponents.count {
                        prevIndex = restoreIndex
                        break
                    }
                }
            }

            let prev = prevComponents[prevIndex]
            if component == prev {
                component.merge(with: prev)
                prevIndex += 1
            }
        }
        return
    }

}
