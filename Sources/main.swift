////
///  main.swift
//

import Darwin

let args = Swift.CommandLine.arguments
let cmd: String = (args.count > 1 ? args[1] : "demo")

let state: AppState
switch cmd {
case "specs":
    let app = App(program: Specs(onEnd: .continue), screen: Screen())
    state = app.run()
case "specs-xcode":
    let app = App(program: Specs(onEnd: .quit), screen: SpecsScreen())
    state = app.run()
default:
    let app = App(program: Demo(), screen: Screen())
    state = app.run()
}

switch state {
    case .quit: exit(EX_OK)
    case .error: exit(EX_IOERR)
}
