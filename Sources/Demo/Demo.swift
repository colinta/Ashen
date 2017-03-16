////
///  Demo.swift
//

import Foundation


struct Demo: Program {
    let initialDemo: ActiveDemo
    let spinnerProgram = SpinnersDemo()
    let canvasProgram = CanvasDemo()
    let inputProgram = InputDemo()
    let flowLayoutProgram = FlowLayoutDemo()
    let gridLayoutProgram = GridLayoutDemo()
    let httpCommandProgram = HttpCommandDemo()

    enum ActiveDemo {
        case spinner
        case canvas
        case input
        case flowLayout
        case gridLayout
        case httpCommand
    }

    struct Model {
        var activeDemo: ActiveDemo
        var spinnerModel: SpinnersDemo.ModelType
        var canvasModel: CanvasDemo.ModelType
        var inputModel: InputDemo.ModelType
        var flowLayoutModel: FlowLayoutDemo.ModelType
        var gridLayoutModel: GridLayoutDemo.ModelType
        var httpCommandModel: HttpCommandDemo.ModelType
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
        case flowLayoutMessage(FlowLayoutDemo.Message)
        case gridLayoutMessage(GridLayoutDemo.Message)
        case httpCommandMessage(HttpCommandDemo.Message)
    }

    init(demo: ActiveDemo = .spinner) {
        initialDemo = demo
    }

    func initial() -> (Model, [Command]) {
        let (spinnerModel, _) = spinnerProgram.initial()
        let (canvasModel, _) = canvasProgram.initial()
        let (inputModel, _) = inputProgram.initial()
        let (flowLayoutModel, _) = flowLayoutProgram.initial()
        let (gridLayoutModel, _) = gridLayoutProgram.initial()
        let (httpCommandModel, httpCommands) = httpCommandProgram.initial()

        return (Model(
            activeDemo: initialDemo,
            spinnerModel: spinnerModel,
            canvasModel: canvasModel,
            inputModel: inputModel,
            flowLayoutModel: flowLayoutModel,
            gridLayoutModel: gridLayoutModel,
            httpCommandModel: httpCommandModel,
            log: []
            ), httpCommands.map { command in
                return command.map { (msg: HttpCommandDemo.Message) -> Message in
                    return Message.httpCommandMessage(msg) }
            })
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
            let (newModel, _, state) =
                spinnerProgram.update(model: &model.spinnerModel, message: spinnerMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .canvas
            }
            model.spinnerModel = newModel
        case let .canvasMessage(canvasMsg):
            let (newModel, _, state) =
                canvasProgram.update(model: &model.canvasModel, message: canvasMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .input
            }
            model.canvasModel = newModel
        case let .inputMessage(inputMsg):
            let (newModel, _, state) =
                inputProgram.update(model: &model.inputModel, message: inputMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .flowLayout
            }
            model.inputModel = newModel
        case let .flowLayoutMessage(flowLayoutMsg):
            let (newModel, _, state) =
                flowLayoutProgram.update(model: &model.flowLayoutModel, message: flowLayoutMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .gridLayout
            }
            model.flowLayoutModel = newModel
        case let .gridLayoutMessage(gridLayoutMsg):
            let (newModel, _, state) =
                gridLayoutProgram.update(model: &model.gridLayoutModel, message: gridLayoutMsg)
            if state == .quit {
                model.log = []
                model.activeDemo = .httpCommand
            }
            model.gridLayoutModel = newModel
        case let .httpCommandMessage(httpCommandMsg):
            let (newModel, httpCommandCommands, state) =
                httpCommandProgram.update(model: &model.httpCommandModel, message: httpCommandMsg)
            if state == .quit {
                return (model, [], .quit)
            }
            model.httpCommandModel = newModel
            let commands = httpCommandCommands.map { $0.map { Message.httpCommandMessage($0) } }
            return (model, commands, .continue)
        }

        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let logHeight = max(0, min(10, screenSize.height - 30))
        let labelHeight = 1
        var components: [Component] = []

        let title: String
        let demo: Component
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
        case .flowLayout:
            title = "FlowLayout Demo"
            demo = flowLayoutProgram
                .render(model: model.flowLayoutModel, in: boxSize)
                .map { (msg: FlowLayoutDemo.Message) -> Demo.Message in
                    return Demo.Message.flowLayoutMessage(msg)
                }
        case .gridLayout:
            title = "GridLayout Demo"
            demo = gridLayoutProgram
                .render(model: model.gridLayoutModel, in: boxSize)
                .map { (msg: GridLayoutDemo.Message) -> Demo.Message in
                    return Demo.Message.gridLayoutMessage(msg)
                }
        case .httpCommand:
            title = "HttpCommand Demo"
            demo = httpCommandProgram
                .render(model: model.httpCommandModel, in: boxSize)
                .map { (msg: HttpCommandDemo.Message) -> Demo.Message in
                    return Demo.Message.httpCommandMessage(msg)
                }
        }

        components.append(Box(
            .topLeft(x: 0, y: labelHeight),
            boxSize,
            components: [demo]))
        components.append(LabelView(.topCenter(y: 0), text: Text(title, attrs: [.underline])))
        components.append(OnKeyPress({ key in return Demo.Message.keypress(key) }, reject: [.signal_ctrl_k]))
        components.append(OnKeyPress({ _ in return Demo.Message.resetLog }, filter: [.signal_ctrl_k]))
        components.append(OnDebug(Message.appendLog))
        components.append(
            Box(
                .bottomLeft(x: 10), Size(width: screenSize.width - 20, height: logHeight),
                border: .single,
                components: [
                    LogView(entries: model.log, screenSize: screenSize)
                ]))

        return Window(components: components)
    }
}
