////
///  EventComponents.swift
//


public class OnTick: Component {
    public typealias OnTickHandler = (Float) -> AnyMessage
    var onTick: OnTickHandler
    var every: Float
    var timeout: Float
    /// Restart the onTick timer
    var reset: Bool

    public init(_ onTick: @escaping OnTickHandler, every: Float = 0.001, reset: Bool = false) {
        self.onTick = onTick
        self.every = every
        self.timeout = every
        self.reset = reset
    }

    override public func merge(with prevComponent: Component) {
        guard !reset else { return }
        guard let prevComponent = prevComponent as? OnTick else { return }
        timeout = prevComponent.timeout
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self
        let myHandler = self.onTick
        let onTick: OnTickHandler = { dt in
            return mapper(myHandler(dt) as! T)
        }
        component.onTick = onTick
        return component
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        guard case let .tick(dt) = event else { return [] }

        let nextTimeout = timeout - dt
        if nextTimeout <= 0 {
            timeout = nextTimeout + every
            return [onTick(dt)]
        }
        else {
            timeout = nextTimeout
            return []
        }
    }
}

public class OnNext: Component {
    public typealias OnNextHandler = () -> AnyMessage
    var onNext: OnNextHandler

    public init(_ onNext: @escaping OnNextHandler) {
        self.onNext = onNext
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self
        let myHandler = self.onNext
        let onNext: OnNextHandler = {
            return mapper(myHandler() as! T)
        }
        component.onNext = onNext
        return component
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case .tick: return [onNext()]
        default: return []
        }
    }
}

public class OnKeyPress: Component {
    public typealias OnKeyHandler = (KeyEvent) -> AnyMessage
    public typealias EmptyKeyHandler = () -> AnyMessage
    var onKey: OnKeyHandler
    var only: [KeyEvent]
    var except: [KeyEvent]

    public convenience init(_ key: KeyEvent, _ onKey: @escaping EmptyKeyHandler) {
        self.init({ _ in return onKey() }, only: [key])
    }

    public init(_ onKey: @escaping OnKeyHandler, only: [KeyEvent] = [], except: [KeyEvent] = []) {
        self.onKey = onKey
        self.only = only
        self.except = except
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self
        let myHandler = self.onKey
        let onKey: OnKeyHandler = { key in
            return mapper(myHandler(key) as! T)
        }
        component.onKey = onKey
        return component
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        guard eventMatches(event) else { return [] }
        switch event {
        case let .key(key):
            return [onKey(key)]
        default: break
        }

        return []
    }

    private func eventMatches(_ event: Event) -> Bool {
        guard
            case let .key(key) = event,
            only.isEmpty || only.contains(key),
            !except.contains(key)
        else { return false }

        return true
    }

    override public func shouldAlwaysProcess(event: Event) -> Bool {
        return eventMatches(event)
    }

    override public func shouldStopProcessing(event: Event) -> Bool {
        return eventMatches(event)
    }
}

public class OnMouse: Component {
    public typealias OnMouseHandler = (MouseEvent) -> AnyMessage
    var onMouse: OnMouseHandler
    var only: [MouseEvent.Event]
    var except: [MouseEvent.Event]

    public init(_ onMouse: @escaping OnMouseHandler, only: [MouseEvent.Event] = [], except: [MouseEvent.Event] = []) {
        self.onMouse = onMouse
        self.only = only
        self.except = except
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self
        let myHandler = self.onMouse
        let onMouse: OnMouseHandler = { key in
            return mapper(myHandler(key) as! T)
        }
        component.onMouse = onMouse
        return component
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .mouse(mouse):
            guard
                only == [] || only.contains(mouse.event),
                !except.contains(mouse.event)
            else { break }
            return [onMouse(mouse)]
        default: break
        }

        return []
    }
}

public class OnDebug: Component {
    public typealias LogHandler = (String) -> AnyMessage
    var onLogEntry: LogHandler

    public init(_ onLogEntry: @escaping LogHandler) {
        self.onLogEntry = onLogEntry
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self
        let myHandler = self.onLogEntry
        let onLogEntry: LogHandler = { entry in
            return mapper(myHandler(entry) as! T)
        }
        component.onLogEntry = onLogEntry
        return component
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .log(entry): return [onLogEntry(entry)]
        default: return []
        }
    }
}

public class OnResize: Component {
    public typealias ResizeHandler = (Size) -> AnyMessage
    var onResize: ResizeHandler

    public init(_ onResize: @escaping ResizeHandler) {
        self.onResize = onResize
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self
        let myHandler = self.onResize
        let onResize: ResizeHandler = { size in
            return mapper(myHandler(size) as! T)
        }
        component.onResize = onResize
        return component
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .window(width, height): return [onResize(Size(width: width, height: height))]
        default: return []
        }
    }
}
