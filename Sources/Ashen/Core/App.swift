////
///  App.swift
//

import Foundation


public enum SystemMessage {
    case quit
    case rerender
}

public enum AppState {
    case quit
    case error
}

public enum LoopState {
    case quit
    case error
    case `continue`

    var shouldQuit: Bool {
        return self != .continue
    }

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

private var debugSilenced = false
private var debugEntries: [String] = []
// prints to stdout when application exits
public func debug(_ entry: Any) {
    guard !debugSilenced else { return }
    debugEntries.append("\(entry)")
}
public func debugSilenced(_ val: Bool) {
    debugSilenced = val
}

private var logEntries: [String] = []
// prints to internal log, using .log system event
public func log(_ entry: Any) {
    if case Event.log(_) = entry { return debug(entry) }

    logEntries.append("\(entry)")
}

let messageThread = DispatchQueue(label: "messageThread")

func sync(_ block: @escaping () -> Void) {
    messageThread.sync { block() }
}

public struct App<ProgramType: Program> {
    let screen: ScreenType
    let program: ProgramType
    private let timeFactor: Float

    public init(program: ProgramType, screen: ScreenType) {
        self.program = program
        self.screen = screen

        var info = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&info)
        timeFactor = Float(info.numer) / Float(info.denom) / 1_000_000_000
    }

    public func run() -> AppState {
        runningApps += 1
        do {
            try screen.setup()
        }
        catch {
            return .error
        }

        program.setup(screen: screen)
        let state = main()
        screen.teardown()
        runningApps -= 1

        if runningApps == 0 {
            while debugEntries.count > 0 {
                print(debugEntries.removeFirst())
            }
        }

        return state
    }

    private func main() -> AppState {
        var prevTimestamp = mach_absolute_time()
        var (model, commands) = program.initial()

        var window = program.render(model: model, in: screen.size)
        var buffer = screen.render(window: window)

        var messageQueue: [ProgramType.MessageType] = []
        let commandBackgroundThread = DispatchQueue(label: "commandBackgroundThread", qos: .background)
        while true {
            for command in commands {
                commandBackgroundThread.async {
                    command.start { msg in
                        if let msg = msg as? ProgramType.MessageType {
                            sync {
                                messageQueue.append(msg)
                            }
                        }
                    }
                }
            }
            commands = []

            let (events, nextTimestamp) = collectSystemEvents(prevTimestamp: prevTimestamp)
            prevTimestamp = nextTimestamp
            var updateAndRender = false
            var rerender = false

            for event in events {
                if case let .key(key) = event, key == .signalQuit {
                    return .quit
                }
                else if case let .key(key) = event, key == .signalInt {
                    return .error
                }
                else if case .window = event {
                    updateAndRender = true
                }
            }

            for event in events {
                for message in window.messages(for: event, shouldStop: false) {
                    if let message = message as? ProgramType.MessageType {
                        sync {
                            messageQueue.append(message)
                        }
                    }
                    else if let message = message as? SystemMessage {
                        switch message {
                        case .rerender:
                            rerender = true
                        case .quit:
                            return .quit
                        }
                    }
                }
            }

            var messageQueueCopy: [ProgramType.MessageType]!
            sync {
                messageQueueCopy = messageQueue
                messageQueue = []
            }

            updateAndRender = updateAndRender || messageQueueCopy.count > 0
            for message in messageQueueCopy {
                let (newModel, newCommands, state) = program.update(model: &model, message: message)
                if state.shouldQuit {
                    return state.appState
                }

                model = newModel
                commands += newCommands
            }

            if updateAndRender {
                let newWindow = program.render(model: model, in: screen.size)
                newWindow.merge(with: window)
                window = newWindow
            }

            if updateAndRender || rerender {
                buffer = screen.render(window: window)
            }
        }
    }

    private func collectSystemEvents(prevTimestamp: UInt64) -> ([Event], UInt64) {
        var events: [Event] = []
        while let systemEvent = screen.nextEvent() {
            events.append(systemEvent)
            if events.count > 10 {
                break
            }
        }

        while logEntries.count > 0 {
            events.append(.log(logEntries.removeFirst()))
        }

        let currentTime = mach_absolute_time()
        let dt: Float = convertDt(now: currentTime, prevTimestamp: prevTimestamp)
        if dt > 0.001 {
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
