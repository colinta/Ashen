////
///  SpinnerView.swift
//

import Foundation


private let spinners = [
    ["⣾", "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽"],
    ["⠁", "⠈", "⠐", "⠠", "⢀", "⡀", "⠄", "⠂"],
    ["⠉", "⠘", "⠰", "⢠", "⣀", "⡄", "⠆", "⠃"],
    ["⠉", "⠑", "⠒", "⠔", "⠤", "⢄", "⣀", "⡠", "⠤", "⠢", "⠒", "⠊"],
    ["⠉", "⠑", "⠃", "⠊", "⠒", "⠢", "⠆", "⠔", "⠤", "⢄", "⡄", "⡠", "⣀", "⢄", "⢠", "⡠", "⠤", "⠢", "⠰", "⠔", "⠒", "⠑", "⠘", "⠊"],
]

class SpinnerView: ComponentView {
    struct Model {
        static var availableSpinners: Int { return spinners.count }
        func chr(index: Int) -> String { return spinner[index] }
        let spinner: [String]

        init(spinner spinnerIndex: Int) {
            self.init(spinner: spinners[spinnerIndex])
        }

        init(spinner: [String]? = nil) {
            self.spinner = spinner ?? spinners.last!
        }
    }

    var index: Int?
    var timeout: Float = 0.05

    let model: Model
    let animating: Bool

    init(_ location: Location, model: Model = Model(), animating: Bool = true) {
        self.model = model
        self.index = nil
        self.animating = animating
        super.init()
        self.location = location
    }

    override func merge(with prevComponent: Component) {
        guard let prevSpinner = prevComponent as? SpinnerView else { return }
        index = prevSpinner.index
        timeout = prevSpinner.timeout
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(width: 1, height: 1)
    }

    override func render(in buffer: Buffer, size _: Size) {
        let chr = model.chr(index: index ?? 0)
        buffer.write(chr, x: 0, y: 0)
    }

    override func messages(for event: Event) -> [AnyMessage] {
        guard animating else { return [] }

        if case let .tick(dt) = event {
            if timeout < 0 {
                timeout = 0.05
                index = ((index ?? 0) + 1) % model.spinner.count
                return [SystemMessage.rerender]
            }
            else {
                timeout -= dt
            }
        }
        return []
    }
}
