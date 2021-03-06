////
///  OnKeyPress.swift
//

public typealias OnKeyEvent<Msg> = (KeyEvent) -> Msg

public enum OnKeyPressOption {
    case only([KeyEvent])
    case except([KeyEvent])
}

public func OnKeyPress<Msg>(_ key: KeyEvent, _ onKeyPress: @escaping @autoclosure SimpleEvent<Msg>)
    -> View<Msg>
{
    OnKeyPress({ _ in onKeyPress() }, options: [.only([key])])
}

public func OnKeyPress<Msg>(
    _ onKeyPress: @escaping OnKeyEvent<Msg>, options: [OnKeyPressOption] = []
) -> View<Msg> {
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
            return ([onKeyPress(key)], [])
        },
        debugName: "OnKeyPress"
    )
}

private func eventMatches(_ key: KeyEvent, only: [KeyEvent], except: [KeyEvent]) -> Bool {
    return only.isEmpty && !except.contains(key) || only.contains(key)
}
