////
///  Spinner.swift
//

private let SPIN_RATE = 0.1

struct SpinnerModel {
    private static let chars = ["⣾", "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽"]
    private let index: Int
    var char: String { SpinnerModel.chars[index] }
    var dt: Double

    init() {
        index = 0
        dt = 0
    }

    init(index: Int, dt: Double) {
        if dt > SPIN_RATE {
            self.index = (index + 1) % SpinnerModel.chars.count
            self.dt = dt
            while self.dt > SPIN_RATE {
                if SPIN_RATE > 0 {
                    self.dt -= SPIN_RATE
                } else {
                    self.dt = 0
                }
            }
        } else {
            self.index = index
            self.dt = dt
        }
    }

    func next(dt: Double) -> SpinnerModel {
        SpinnerModel(index: index, dt: self.dt + dt)
    }
}

public func Spinner<Msg>() -> View<Msg> {
    View(
        preferredSize: { _ in Size(width: 1, height: 1) },
        render: { viewport, buffer in
            guard !viewport.isEmpty else { return }

            let model: SpinnerModel = buffer.retrieve() ?? SpinnerModel()
            buffer.write(model.char, at: .zero)
            buffer.store(model)
        },
        events: { event, buffer in
            guard
                case let .tick(dt) = event,
                let model: SpinnerModel = buffer.retrieve()
            else { return ([], [event]) }

            buffer.store(model.next(dt: dt))
            return ([], [event])
        },
        debugName: "Spinner"
    )
}
