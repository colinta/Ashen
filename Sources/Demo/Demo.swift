////
///  Demo.swift
//

import Foundation


struct Demo: Program {
    let spinnerProgram = SpinnersDemo()
    let canvasProgram = CanvasDemo()
    let inputProgram = InputDemo()
    let rougeProgram = Rouge()

    enum ActiveDemo {
        case spinner
        case canvas
        case input
        case rouge
    }

    struct Model {
        var activeDemo: ActiveDemo
        var spinnerModel: SpinnersDemo.ModelType
        var canvasModel: CanvasDemo.ModelType
        var inputModel: InputDemo.ModelType
        var rougeModel: Rouge.ModelType
        var log: [String]
    }

    enum Message {
        case quit
        case keypress(KeyEvent)
        case resetLog
        case appendLog(String)
        case spinnerMessage(SpinnersDemo.Message)
        case canvasMessage(CanvasDemo.Message)
        case inputMessage(InputDemo.Message)
        case rougeMessage(Rouge.Message)
    }

    enum Command {
        case spinnerCommand(SpinnersDemo.CommandType)
        case canvasCommand(CanvasDemo.CommandType)
        case inputCommand(InputDemo.CommandType)
        case rougeCommand(Rouge.CommandType)
    }

    func model() -> Model {
        return Model(
            activeDemo: .spinner,
            spinnerModel: spinnerProgram.model(),
            canvasModel: canvasProgram.model(),
            inputModel: inputProgram.model(),
            rougeModel: rougeProgram.model(),
            log: []
            )
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case let .keypress(key):
            model.log.append("Pressed \(key)")
        case .resetLog:
            model.log = []
        case let .appendLog(entry):
            model.log.append(entry)
        case let .spinnerMessage(spinnerMsg):
            let (newModel, spinnerCommands, state) =
                spinnerProgram.update(model: &model.spinnerModel, message: spinnerMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .canvas
            }
            model.spinnerModel = newModel
            let commands = spinnerCommands.map { Command.spinnerCommand($0) }
            return (model, commands, .continue)
        case let .canvasMessage(canvasMsg):
            let (newModel, canvasCommands, state) =
                canvasProgram.update(model: &model.canvasModel, message: canvasMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .input
            }
            model.canvasModel = newModel
            let commands = canvasCommands.map { Command.canvasCommand($0) }
            return (model, commands, .continue)
        case let .inputMessage(inputMsg):
            let (newModel, inputCommands, state) =
                inputProgram.update(model: &model.inputModel, message: inputMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .rouge
            }
            model.inputModel = newModel
            let commands = inputCommands.map { Command.inputCommand($0) }
            return (model, commands, .continue)
        case let .rougeMessage(rougeMsg):
            let (newModel, rougeCommands, state) =
                rougeProgram.update(model: &model.rougeModel, message: rougeMsg)
            if state == .quit {
                return (model, [], .quit)
            }
            model.rougeModel = newModel
            let commands = rougeCommands.map { Command.rougeCommand($0) }
            return (model, commands, .continue)
        }

        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> ComponentType {
        let logHeight = 10
        let labelHeight = 1
        var components: [ComponentType] = []
        components.append(OnDebug(Message.appendLog))
        components.append(LogView(y: screenSize.height - logHeight, entries: model.log, screenSize: screenSize))

        let title: String
        let demo: ComponentType
        let boxSize = Size(width: screenSize.width, height: screenSize.height - logHeight - labelHeight)
        switch model.activeDemo {
        case .spinner:
            title = "SpinnerView Demo"
            demo = spinnerProgram
                .render(model: model.spinnerModel, in: boxSize)
                .map { (msg: SpinnersDemo.Message) -> Demo.Message in
                    return Demo.Message.spinnerMessage(msg)
                }
        case .canvas:
            title = "Canvas Demo"
            demo = canvasProgram
                .render(model: model.canvasModel, in: boxSize)
                .map { (msg: CanvasDemo.Message) -> Demo.Message in
                    return Demo.Message.canvasMessage(msg)
                }
        case .input:
            title = "InputView Demo"
            demo = inputProgram
                .render(model: model.inputModel, in: boxSize)
                .map { (msg: InputDemo.Message) -> Demo.Message in
                    return Demo.Message.inputMessage(msg)
                }
        case .rouge:
            title = "Rouge"
            demo = rougeProgram
                .render(model: model.rougeModel, in: boxSize)
                .map { (msg: Rouge.Message) -> Demo.Message in
                    return Demo.Message.rougeMessage(msg)
                }
        }

        components.append(Box(
            .tl(x: 0, y: labelHeight),
            boxSize,
            components: [demo]))
        components.append(LabelView(.tc(y: 0), text: Text(title, attrs: [.underline])))
        components.append(OnKeyPress({ key in return Demo.Message.keypress(key) }, reject: [.signal_ctrl_k]))
        components.append(OnKeyPress({ _ in return Demo.Message.resetLog }, filter: [.signal_ctrl_k]))

        return Window(components: components)
    }

    func start(command: Command, done: @escaping (Message) -> Void) {
        switch command {
        case let .spinnerCommand(cmd):
            spinnerProgram.start(command: cmd) { msg in done(Message.spinnerMessage(msg)) }
        case let .canvasCommand(cmd):
            canvasProgram.start(command: cmd) { msg in done(Message.canvasMessage(msg)) }
        case let .inputCommand(cmd):
            inputProgram.start(command: cmd) { msg in done(Message.inputMessage(msg)) }
        case let .rougeCommand(cmd):
            rougeProgram.start(command: cmd) { msg in done(Message.rougeMessage(msg)) }
        }
    }

}
