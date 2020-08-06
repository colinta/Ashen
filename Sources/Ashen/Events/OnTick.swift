////
///  OnTick.swift
//

public typealias OnTickEvent<Msg> = (Double) -> Msg

public enum OnTickOptions {
    case every(Double)
    case paused(Bool)
}

struct OnTickModel {
    let timeout: Double
}

public func OnTick<Msg>(_ onTick: @escaping OnTickEvent<Msg>, options: [OnTickOptions] = [])
    -> View<Msg>
{
    var every = 0.001
    var paused = false
    for opt in options {
        switch opt {
        case let .every(everyOpt):
            every = everyOpt
        case let .paused(pausedOpt):
            paused = pausedOpt
        }
    }

    return View<Msg>(
        preferredSize: { _ in .zero },
        render: { _, _ in },
        events: { event, buffer in
            guard
                !paused,
                case let .tick(dt) = event
            else { return ([], [event]) }

            guard
                let model: OnTickModel = buffer.retrieve()
            else {
                buffer.store(OnTickModel(timeout: every))
                return ([], [event])
            }

            let nextTimeout = model.timeout - dt
            if nextTimeout <= 0 {
                buffer.store(OnTickModel(timeout: nextTimeout + every))
                return ([onTick(dt)], [event])
            } else {
                buffer.store(OnTickModel(timeout: nextTimeout))
                return ([], [event])
            }
        },
        debugName: "OnTick"
    )
}
