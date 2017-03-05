////
///  GridLayoutDemo.swift
//

import Darwin


struct GridLayoutDemo: Program {
    enum Message {
        case quit
        case randomize
    }

    struct Model {
        var rows: [(weight: Float, columns: [(weight: Float, bg: String)])]

        init() {
            let strings = [".", "%", "`", ",", "$", "#", "@", ":", "'", "?",]
            let rowCount = 2 + Int(arc4random_uniform(UInt32(4)))
            rows = (0 ..< rowCount).map { _ in
                let weight: Float = 1 + 5 * Float(drand48())
                let colCount = 2 + Int(arc4random_uniform(UInt32(4)))
                return (weight: weight, columns: (0 ..< colCount).map { _ in
                    let weight: Float = 1 + 5 * Float(drand48())
                    let index = Int(arc4random_uniform(UInt32(strings.count)))
                    return (weight: weight, bg: strings[index])
                })
            }
        }
    }

    func initial() -> (Model, [AnyCommand]) {
        return (Model(), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [AnyCommand], LoopState)
    {
        switch message {
        case .quit:
            return (model, [], .quit)
        case .randomize:
            model = Model()
            return (model, [], .continue)
        }
    }

    func render(model: Model, in screenSize: Size) -> Component {
        return Window(components: [
            OnKeyPress(.key_enter, { return Message.quit }),
            OnKeyPress(.key_tab, { return Message.randomize }),
            GridLayout(.topLeft(y: 1), screenSize,
                rows: model.rows.map { row in
                    return .row(weight: row.weight, row.columns.map { col in
                        let box = Box(.tl(.zero), .zero, border: nil, background: col.bg, components: [])
                        return .column(weight: col.weight, box)
                    })
                }),
            ])
    }

    func start(command: AnyCommand, done: @escaping (Message) -> Void) {
    }
}
