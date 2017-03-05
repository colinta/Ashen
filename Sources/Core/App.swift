////
///  App.swift
//

import Darwin


enum SystemMessage {
    case rerender
}

enum AppState {
    case quit
    case error
}

enum LoopState {
    case quit
    case error
    case `continue`

    var appState: AppState {
        switch self {
        case .error:
            return .error
        default:
            return .quit
        }
    }
}


// when running specs there are multiple apps running; we only want the
// debugging log to output when the "outermost" application exits.
private var runningApps: Int = 0

private var logEntries: [String] = []
// prints to stdout when application exits
func log(_ entry: Any) {
    logEntries.append("\(entry)")
}

private var debugEntries: [String] = []
// prints to internal debug log, using .debug system event
func debug(_ entry: Any) {
    if case Event.debug(_) = entry { return log(entry) }

    debugEntries.append("\(entry)")
}

struct App<T: Program> {
    let screen: ScreenType
    let program: T
    private let timeFactor: Float

    init(program: T, screen: ScreenType) {
        self.program = program
        self.screen = screen

        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        timeFactor = Float(info.numer) / Float(info.denom) / 1_000_000_000
    }

    func run() -> AppState {
        runningApps += 1
        screen.setup()
        let state = main()
        screen.teardown()
        runningApps -= 1

        if runningApps == 0 {
            while logEntries.count > 0 {
                print(logEntries.removeFirst())
            }
        }

        return state
    }

    func main() -> AppState {
        var state: LoopState = .continue
        var prevTimestamp = mach_absolute_time()
        var prevState: [(T.ModelType, Component, Screen.Chars)] = []
        var inThePast: Int?
        var (model, commands) = program.initial()

        var window = program.render(model: model, in: screen.size)
        let chars = screen.render(window)
        prevState.append((model, window, chars))

        while state == .continue {
            var messageQueue: [T.MessageType] = []
            for command in commands {
                program.start(command: command) { (msg: T.MessageType) in
                    messageQueue.append(msg)
                }
            }

            let (events, nextTimestamp) = flushEvents(prevTimestamp: prevTimestamp)
            prevTimestamp = nextTimestamp
            var updateAndRender = false
            var rerender = false

            for event in events {
                if case let .key(key) = event, key == .signal_quit {
                    return .quit
                }
                else if case let .key(key) = event, key == .signal_int {
                    return .error
                }
                else if case .window = event {
                    updateAndRender = true
                }
                else if case let .key(key) = event, key == .signal_ctrl_z {
                    inThePast = max(0, (inThePast ?? prevState.count) - 1)
                }
                else if case let .key(key) = event, key == .signal_ctrl_x {
                    inThePast = min(prevState.count - 1, (inThePast ?? prevState.count) + 1)
                }
                else if case let .key(key) = event, key == .key_space, let pastIndex = inThePast {
                    let (newModel, newWindow, _) = prevState[pastIndex]
                    model = newModel
                    window = newWindow
                    rerender = true
                    prevState = Array(prevState[0 ..< pastIndex])
                    inThePast = nil
                }
            }

            if let pastIndex = inThePast {
                let (_, _, chars) = prevState[pastIndex]
                screen.render(chars: chars)
                messageQueue = []
                continue
            }
            else {
                for event in events {
                    for message in window.messages(for: event) {
                        if let message = message as? T.MessageType {
                            messageQueue.append(message)
                        }
                        else if let message = message as? SystemMessage, inThePast == nil {
                            switch message {
                            case .rerender:
                                rerender = true
                            }
                        }
                    }
                }

                while messageQueue.count > 0 {
                    let message = messageQueue.removeFirst()
                    let (newModel, newCommands, newState) = program.update(model: &model, message: message)
                    if newState != .continue { return newState.appState }
                    state = newState
                    model = newModel
                    commands = newCommands

                    updateAndRender = true
                }
            }

            if updateAndRender {
                let newWindow = program.render(model: model, in: screen.size)
                newWindow.merge(with: window)
                window = newWindow
            }

            if updateAndRender || rerender {
                let chars = screen.render(window)

                prevState.append((model, window, chars))
            }
        }

        return .quit
    }

    private func flushEvents(prevTimestamp: UInt64) -> ([Event], UInt64) {
        var events: [Event] = []
        while let systemEvent = screen.nextEvent() {
            events.append(systemEvent)
            if events.count > 10 {
                break
            }
        }

        while debugEntries.count > 0 {
            events.append(.debug(debugEntries.removeFirst()))
        }

        let currentTime = mach_absolute_time()
        let dt: Float = convertDt(now: currentTime, prevTimestamp: prevTimestamp)
        if dt > 0.01666 {
            events.append(.tick(dt))
            return (events, currentTime)
        }
        else {
            return (events, prevTimestamp)
        }
    }

    private func convertDt(now currentTime: UInt64, prevTimestamp: UInt64) -> Float {
        return Float((currentTime - prevTimestamp)) * timeFactor
    }

}
