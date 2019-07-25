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

public class SpinnerView: ComponentView {
    public struct Model {
        public static var availableSpinners: Int { return spinners.count }
        public static let heroku: Model = Model(spinner: spinners[0])
        public static let dot: Model = Model(spinner: spinners[1])
        public static let snake: Model = Model(spinner: spinners[2])
        public static let ladder: Model = Model(spinner: spinners[3])
        public static let bounce: Model = Model(spinner: spinners[4])
        public static let `default`: Model = .heroku

        func chr(index: Int) -> String { return spinner[index] }
        let spinner: [String]

        public init(spinner spinnerIndex: Int) {
            self.init(spinner: spinners[spinnerIndex])
        }

        public init(spinner: [String]) {
            self.spinner = spinner
        }
    }

    var index: Int?
    var timeout: Float = 0.05

    let model: Model
    let color: Int?
    let animating: Bool

    public init(_ location: Location, model: Model = Model.default, color: Int? = nil, animating: Bool = true) {
        self.model = model
        self.index = nil
        self.color = color
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
        let attrs: [Attr]
        if let color = color {
            attrs = [.color(color)]
        }
        else {
            attrs = []
        }
        buffer.write(AttrChar(chr, attrs), x: 0, y: 0)
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
