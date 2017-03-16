////
///  main.swift
//

import Darwin

let args = Swift.CommandLine.arguments
let cmd: String = (args.count > 1 ? args[1] : "demo")
let verbose = args.index(where: { $0 == "--verbose" }) != nil

let state: AppState
if cmd.hasPrefix("specs") {
    let onEnd: LoopState
    let screen: ScreenType
    if cmd.hasSuffix("-xcode") {
        onEnd = .quit
        screen = SpecsScreen()
    }
    else {
        onEnd = .continue
        screen = NcursesScreen()
    }

    let app = App(program: SpecsProgram(verbose: verbose, onEnd: onEnd), screen: screen)
    state = app.run()
}
else if cmd == "http" {
    let app = App(program: Demo(demo: .httpCommand), screen: NcursesScreen())
    state = app.run()
}
else if cmd == "blackbox" {
    let app = App(program: BlackBoxGame(), screen: NcursesScreen())
    state = app.run()
}
else {
    let app = App(program: Demo(), screen: NcursesScreen())
    state = app.run()
}

switch state {
    case .quit: exit(EX_OK)
    case .error: exit(EX_IOERR)
}
