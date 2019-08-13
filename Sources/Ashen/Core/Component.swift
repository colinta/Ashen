////
///  Component.swift
//


open class Component: Equatable {
    var id: String?

    public init() {}

    open func messages(for _: Event) -> [AnyMessage] {
        return []
    }

    func messages(for event: Event, shouldStop: Bool) -> [AnyMessage] {
        return messages(for: event)
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

    open func shouldAlwaysProcess(event: Event) -> Bool {
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

open class ComponentView: Component {
    open var location: Location = .topLeft()
    open func desiredSize() -> DesiredSize {
        return DesiredSize()
    }
}

open class ComponentLayout: ComponentView {
    public var components: [Component] = []
    // public var views: [ComponentView] { return components.compactMap { $0 as? ComponentView } }

    override open func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let window = self
        window.components = components.map { comp in
            return comp.map(mapper)
        }
        return window
    }

    override func messages(for event: Event, shouldStop shouldStopParent: Bool) -> [AnyMessage] {
        var messages: [AnyMessage] = self.messages(for: event)
        var shouldStop = shouldStopParent
        for component in components {
            guard !shouldStop || component.shouldAlwaysProcess(event: event) else { continue }

            messages += component.messages(for: event, shouldStop: shouldStop)

            if component.shouldStopProcessing(event: event) {
                shouldStop = true
            }
        }
        return messages
    }

    override open func render(to buffer: Buffer, in rect: Rect) {
        Window.render(views: components, to: buffer, in: rect)
    }

    override open func shouldStopProcessing(event: Event) -> Bool {
        for component in components {
            if component.shouldStopProcessing(event: event) {
                return true
            }
        }
        return false
    }

    override open func shouldAlwaysProcess(event: Event) -> Bool {
        for component in components {
            if component.shouldAlwaysProcess(event: event) {
                return true
            }
        }
        return false
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
    override open func merge(with prevComponent: Component) {
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
