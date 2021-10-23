////
///  Ashen.swift
//

import Foundation

enum ExitCode<T> {
    case quit(T)
    case quitAnd(T, () throws -> Void)

    var model: T {
        switch self {
        case let .quit(model):
            return model
        case let .quitAnd(model, _):
            return model
        }
    }
}

/// This is how you run an Ashen program.
public func ashen<Model, Msg>(_ program: Program<Model, Msg>) throws {
    let screen = TermboxScreen()

    try screen.setup()
    defer {
    }

    let exit = main(screen, program)
    screen.teardown()
    program.unmount?(exit.model)

    while debugEntries.count > 0 {
        print(debugEntries.removeFirst())
    }

    if case let .quitAnd(_, closure) = exit {
        try closure()
    }
}

let messageThread = DispatchQueue(label: "messageThread")
let commandThread = DispatchQueue(
    label: "commandThread",
    qos: .background
)

func sync(_ block: @escaping () -> Void) {
    messageThread.sync(execute: block)
}

func background(_ block: @escaping () -> Void) {
    commandThread.async(execute: block)
}

private func main<Model, Msg>(
    _ screen: TermboxScreen,
    _ program: Program<Model, Msg>
) -> ExitCode<Model> {
    let initial = program.initial()
    var model = initial.model
    var cmds = [initial.command]
    var view: View<Msg>!

    var prevTimestamp = mach_absolute_time()
    var info = mach_timebase_info(numer: 0, denom: 0)
    mach_timebase_info(&info)
    let timeFactor = Double(info.numer) / Double(info.denom) / 1_000_000_000

    var queue: [Msg] = []
    var shouldRender = true
    var prevBuffer: Buffer? = nil
    var prevSize: Size? = nil

    let runLoop = RunLoop.current
    while runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01)) {
        cmds.forEach { cmd in
            background {
                cmd.run({ msg in
                    sync {
                        queue.append(msg)
                    }
                })
            }
        }
        cmds = []

        var currentQueue: [Msg] = []
        sync {
            currentQueue = queue
            queue = []
        }
        for msg in currentQueue {
            let newState = program.update(model, msg)
            switch newState {
            case .noChange:
                break
            case let .update(newModel, newCommand):
                model = newModel
                cmds += [newCommand]
                shouldRender = true
            case .quit:
                return .quit(model)
            case let .quitAnd(closure):
                return .quitAnd(model, closure)
            }
        }

        let screenSize = screen.size

        let buffer: Buffer
        if shouldRender || screenSize != prevSize {
            buffer = Buffer(size: screenSize, prev: prevBuffer)

            view = Window(program.view(model))
            view.render(LocalViewport(screenSize), buffer)
            screen.render(buffer: buffer)
            shouldRender = false
            prevBuffer = buffer
            prevSize = screen.size
        } else {
            buffer = prevBuffer!
        }

        let (events, nextTimestamp) = collectSystemEvents(
            screen: screen, prevTimestamp: prevTimestamp, timeFactor: timeFactor)
        prevTimestamp = nextTimestamp

        for event in events {
            if case let .key(key) = event,
                key == .signalInt {
                return .quit(model)
            }

            let (msgs, viewEvents) = view.events(event, buffer)
            sync {
                msgs.forEach { queue.append($0) }
            }

            for event in viewEvents {
                guard case .redraw = event else { continue }
                shouldRender = true
                break
            }
        }
    }
    return .quit(model)
}

private func collectSystemEvents(screen: TermboxScreen, prevTimestamp: UInt64, timeFactor: Double)
    -> ([Event], UInt64)
{
    var events: [Event] = []
    while let systemEvent = screen.nextEvent() {
        events.append(systemEvent)
        if events.count > 10 {
            break
        }
    }

    // events += logEntries.map { .log($0) }
    // logEntries = []

    let currentTime = mach_absolute_time()
    let dt: Double = convertDt(
        now: currentTime, prevTimestamp: prevTimestamp, timeFactor: timeFactor)
    if dt > 0.01 {
        events.append(.tick(dt))
        return (events, currentTime)
    } else {
        return (events, prevTimestamp)
    }
}

private func convertDt(now currentTime: UInt64, prevTimestamp: UInt64, timeFactor: Double) -> Double
{
    Double((currentTime - prevTimestamp)) * timeFactor
}
