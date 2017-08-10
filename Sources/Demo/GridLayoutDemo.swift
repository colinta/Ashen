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

    func initial() -> (Model, [Command]) {
        return (Model(), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
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
        let gridSize = Size(width: screenSize.width, height: screenSize.height - 1)
        return Window(components: [
            OnKeyPress(.key_enter, { return Message.quit }),
            OnKeyPress(.key_tab, { return Message.randomize }),
            GridLayout(.topLeft(y: 1), gridSize,
                rows: model.rows.flatMap { row -> [GridLayout.Row] in
                    let b = Box(background: "-")
                    return [
                        .row(weight: .relative(row.weight), row.columns.flatMap { col -> [GridLayout.Column] in
                            return [
                                .column(weight: .relative(col.weight), Box(background: col.bg)),
                                .column(weight: .fixed(1), Box(background: "|"))
                            ]
                        }),
                        .row(weight: .fixed(1), [b]),
                    ]
                }),
            ])
    }
}
