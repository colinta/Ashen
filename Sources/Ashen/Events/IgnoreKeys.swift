////
///  IgnoreKeys.swift
//

public enum IgnoreKeysOption {
    case only([KeyEvent])
    case except([KeyEvent])
}

public func IgnoreKeys<Msg>(except keys: [KeyEvent] = []) -> View<Msg> {
    IgnoreKeys(options: [.except(keys)])
}

public func IgnoreKeys<Msg>(only keys: KeyEvent...) -> View<Msg> {
    IgnoreKeys(options: [.only(keys)])
}

private func IgnoreKeys<Msg>(options: [IgnoreKeysOption] = []) -> View<Msg> {
    var only: [KeyEvent] = []
    var except: [KeyEvent] = []
    for opt in options {
        switch opt {
        case let .only(onlyOpt):
            only = onlyOpt
            except = []
        case let .except(exceptOpt):
            except = exceptOpt
            only = []
        }
    }

    return View<Msg>(
        preferredSize: { _ in .zero },
        render: { _, _ in },
        events: { event, buffer in
            guard
                case let .key(key) = event,
                eventMatches(key, only: only, except: except)
            else { return ([], [event]) }
            return ([], [])
        },
        debugName: "IgnoreKeys"
    )
}

private func eventMatches(_ key: KeyEvent, only: [KeyEvent], except: [KeyEvent]) -> Bool {
    return only.isEmpty && !except.contains(key) || only.contains(key)
}
