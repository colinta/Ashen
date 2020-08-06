////
///  Ashen.swift
//

import Foundation

public func Ashen<Model, Msg>(_ program: Program<Model, Msg>) throws {
    let screen = TermboxScreen()

    signal(SIGINT, SIG_IGN)
    let sourceInterrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    sourceInterrupt.setEventHandler {
        screen.teardown()
        exit(SIGINT)
    }
    sourceInterrupt.resume()

    defer {
        screen.teardown()

        while debugEntries.count > 0 {
            print(debugEntries.removeFirst())
        }
    }

    try main(screen, program)
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
) throws {
    try screen.setup()

    let initial = program.initial()
    var model = initial.model
    var cmds = initial.commands
    var view: View<Msg>!

    var prevTimestamp = mach_absolute_time()
    var info = mach_timebase_info(numer: 0, denom: 0)
    mach_timebase_info(&info)
    let timeFactor = Double(info.numer) / Double(info.denom) / 1_000_000_000

    var queue: [Msg] = []
    var shouldRender = true
    var prevBuffer: Buffer? = nil
    var prevSize: Size? = nil

    while true {
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
            let newState = program.update(&model, msg)
            switch newState {
            case .noChange:
                break
            case let .update(newModel, newCommand):
                model = newModel
                cmds += newCommand
                shouldRender = true
            case .quit:
                return
            case let .quitAnd(closure):
                try closure()
                return
            }
        }

        let screenSize = screen.size

        let buffer: Buffer
        if shouldRender || screenSize != prevSize {
            buffer = Buffer(size: screenSize, prev: prevBuffer)
            view = Window(program.view(model, screenSize))
            view.render(Viewport(screenSize), buffer)
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
            if case let .key(key) = event, key == .signalQuit {
                return
            } else if case let .key(key) = event, key == .signalInt {
                return
            }

            let (msgs, events) = view.events(event, buffer)
            sync {
                msgs.forEach { queue.append($0) }
            }

            for event in events {
                if case .redraw = event {
                    shouldRender = true
                    break
                }
            }
        }
    }
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
    if dt > 0.001 {
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
