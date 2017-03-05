////
///  EventComponents.swift
//


class OnTick: Component {
    typealias OnTickHandler = (Float) -> AnyMessage
    var onTick: OnTickHandler
    var every: Float
    var timeout: Float
    /// Restart the onTick timer
    var reset: Bool

    init(_ onTick: @escaping OnTickHandler, every: Float = 0.001, reset: Bool = false) {
        self.onTick = onTick
        self.every = every
        self.timeout = every
        self.reset = reset
    }

    override func merge(with prevComponent: Component) {
        guard !reset else { return }
        guard let prevComponent = prevComponent as? OnTick else { return }
        prevComponent.timeout = timeout
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> OnTick {
        let component = self
        let myHandler = self.onTick
        let onTick: OnTickHandler = { dt in
            return mapper(myHandler(dt) as! T)
        }
        component.onTick = onTick
        return component
    }

    override func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .tick(dt):
            let nextTimeout = timeout - dt
            if nextTimeout <= 0 {
                timeout = nextTimeout + every
                return [onTick(dt)]
            }
            else {
                timeout = nextTimeout
            }
        default: break
        }
        return []
    }
}

class OnNext: Component {
    typealias OnNextHandler = () -> AnyMessage
    var onNext: OnNextHandler

    init(_ onNext: @escaping OnNextHandler) {
        self.onNext = onNext
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> OnNext {
        let component = self
        let myHandler = self.onNext
        let onNext: OnNextHandler = {
            return mapper(myHandler() as! T)
        }
        component.onNext = onNext
        return component
    }

    override func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case .tick: return [onNext()]
        default: return []
        }
    }
}

class OnKeyPress: Component {
    typealias OnKeyHandler = (KeyEvent) -> AnyMessage
    typealias EmptyKeyHandler = () -> AnyMessage
    var onKey: OnKeyHandler
    var filter: [KeyEvent]
    var reject: [KeyEvent]

    convenience init(_ key: KeyEvent, _ onKey: @escaping EmptyKeyHandler) {
        self.init({ _ in return onKey() }, filter: [key])
    }

    init(_ onKey: @escaping OnKeyHandler, filter: [KeyEvent] = [], reject: [KeyEvent] = []) {
        self.onKey = onKey
        self.filter = filter
        self.reject = reject
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> OnKeyPress {
        let component = self
        let myHandler = self.onKey
        let onKey: OnKeyHandler = { key in
            return mapper(myHandler(key) as! T)
        }
        component.onKey = onKey
        return component
    }

    override func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .key(key):
            guard
                filter == [] || filter.contains(key),
                !reject.contains(key)
            else { break }
            return [onKey(key)]
        default: break
        }

        return []
    }
}

class OnDebug: Component {
    typealias LogHandler = (String) -> AnyMessage
    var onLogEntry: LogHandler

    init(_ onLogEntry: @escaping LogHandler) {
        self.onLogEntry = onLogEntry
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> OnDebug {
        let component = self
        let myHandler = self.onLogEntry
        let onLogEntry: LogHandler = { entry in
            return mapper(myHandler(entry) as! T)
        }
        component.onLogEntry = onLogEntry
        return component
    }

    override func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .debug(entry): return [onLogEntry(entry)]
        default: return []
        }
    }
}

class OnResize: Component {
    typealias ResizeHandler = (Size) -> AnyMessage
    var onResize: ResizeHandler

    init(_ onResize: @escaping ResizeHandler) {
        self.onResize = onResize
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> OnResize {
        let component = self
        let myHandler = self.onResize
        let onResize: ResizeHandler = { size in
            return mapper(myHandler(size) as! T)
        }
        component.onResize = onResize
        return component
    }

    override func messages(for event: Event) -> [AnyMessage] {
        switch event {
        case let .window(width, height): return [onResize(Size(width: width, height: height))]
        default: return []
        }
    }
}
