////
///  main.swift
//

import Darwin

let args = Swift.CommandLine.arguments
let cmd: String = (args.count > 1 ? args[1] : "demo")
let verbose = args.firstIndex(where: { $0 == "--verbose" }) != nil

let onEnd: LoopState
let screen: ScreenType
if cmd.hasSuffix("-xcode") {
    onEnd = .quit
    screen = SpecsScreen()
}
else {
    onEnd = .continue
    screen = TermboxScreen()
}

let app = App(program: SpecsProgram(verbose: verbose, onEnd: onEnd), screen: screen)
let state = app.run()

switch state {
case .quit: exit(EX_OK)
case .error: exit(EX_IOERR)
}
