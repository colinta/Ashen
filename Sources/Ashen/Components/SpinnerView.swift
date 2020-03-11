////
///  SpinnerView.swift
//

import Foundation


private let spinners = [
    ["⣾", "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽"],
    ["⠁", "⠈", "⠐", "⠠", "⢀", "⡀", "⠄", "⠂"],
    ["⠉", "⠘", "⠰", "⢠", "⣀", "⡄", "⠆", "⠃"],
    ["⠉", "⠑", "⠒", "⠔", "⠤", "⢄", "⣀", "⡠", "⠤", "⠢", "⠒", "⠊"],
    [
        "⠉", "⠑", "⠃", "⠊", "⠒", "⠢", "⠆", "⠔", "⠤", "⢄", "⡄", "⡠", "⣀", "⢄", "⢠", "⡠", "⠤", "⠢",
        "⠰", "⠔", "⠒", "⠑", "⠘", "⠊"
    ],
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
        public static func width(_ width: Int) -> Model {
            guard width > 0 else { return Model(spinner: []) }

            var lPad = 0
            var rPad = 0
            var spinner: [String] = []
            var content = ""
            for x in 0..<width {
                lPad = x
                rPad = width - lPad - 1
                if lPad > 0 {
                    content = ""
                    content.append(String(repeating: " ", count: lPad - 1))
                    content.append("⠈")
                    content.append("⠁")
                    content.append(String(repeating: " ", count: rPad))
                    spinner.append(content)
                }
                content = ""
                content.append(String(repeating: " ", count: lPad))
                content.append("⠉")
                content.append(String(repeating: " ", count: rPad))
            }
            spinner.append(String(repeating: " ", count: lPad) + "⠘")
            spinner.append(String(repeating: " ", count: lPad) + "⠰")
            spinner.append(String(repeating: " ", count: lPad) + "⢠")

            for x in 0..<width {
                rPad = x
                lPad = width - rPad - 1
                if lPad > 0 {
                    content = ""
                    content.append(String(repeating: " ", count: lPad - 1))
                    content.append("⢀")
                    content.append("⡀")
                    content.append(String(repeating: " ", count: rPad))
                    spinner.append(content)
                }
                content = ""
                content.append(String(repeating: " ", count: lPad))
                content.append("⣀")
                content.append(String(repeating: " ", count: rPad))
            }
            spinner.append(String(repeating: " ", count: lPad) + "⡄")
            spinner.append(String(repeating: " ", count: lPad) + "⠆")
            spinner.append(String(repeating: " ", count: lPad) + "⠃")
            return Model(spinner: spinner)
        }

        func content(index: Int) -> String { return spinner[index] }
        let spinner: [String]

        public init(spinner spinnerIndex: Int) {
            self.init(spinner: spinners[spinnerIndex % Model.availableSpinners])
        }

        public init(spinner: [String]) {
            self.spinner = spinner
        }
    }

    var index: Int?
    let initialTimeout: Float = 0.05
    var timeout: Float

    let model: Model
    let foreground: Color?
    let background: Color?
    let isAnimating: Bool

    public init(
        at location: Location = .mc(.zero),
        model: Model = Model.default,
        foreground: Color? = nil,
        background: Color? = nil,
        isAnimating: Bool = true
    ) {
        self.model = model
        self.index = nil
        self.foreground = foreground
        self.background = background
        self.isAnimating = isAnimating
        self.timeout = initialTimeout
        super.init()
        self.location = location
    }

    override public func merge(with prevComponent: Component) {
        guard let prevSpinner = prevComponent as? SpinnerView else { return }
        index = prevSpinner.index
        timeout = prevSpinner.timeout
    }

    override public func desiredSize() -> DesiredSize {
        let width = model.spinner.reduce(0) { width, str in
            return max(width, str.count)
        }
        return DesiredSize(width: width, height: 1)
    }

    override public func render(to buffer: Buffer, in _: Rect) {
        for (x, chr) in model.content(index: index ?? 0).enumerated() {
            var attrs: [Attr] = []
            if let foreground = foreground {
                attrs.append(.foreground(foreground))
            }
            if let background = background {
                attrs.append(.background(background))
            }
            buffer.write(AttrChar(chr, attrs), x: x, y: 0)
        }
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        guard isAnimating else { return [] }

        if case let .tick(dt) = event {
            if timeout < 0 {
                timeout = initialTimeout
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
