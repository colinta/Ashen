////
///  Frame.swift
//

public enum FrameOptions {
    case alignment(Alignment)
}

extension View {
    public func centered() -> View<Msg> {
        Frame(self, [])
    }

    public func aligned(_ alignment: Alignment) -> View<Msg> {
        Frame(self, [.alignment(alignment)])
    }
}

public func Frame<Msg>(_ inside: View<Msg>, _ options: [FrameOptions] = []) -> View<Msg> {
    var alignment: Alignment = .topCenter
    for opt in options {
        switch opt {
        case let .alignment(alignmentOpt):
            alignment = alignmentOpt
        }
    }

    return View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { rect, buffer in
            let innerPreferredSize = inside.preferredSize(rect.size)

            let positionX: Int
            let positionY: Int
            switch alignment {
            case .topLeft, .middleLeft, .bottomLeft:
                positionX = 0
            case .topCenter, .middleCenter, .bottomCenter:
                positionX = Int((rect.width - innerPreferredSize.width) / 2)
            case .topRight, .middleRight, .bottomRight:
                positionX = rect.width - innerPreferredSize.width
            }
            switch alignment {
            case .topLeft, .topCenter, .topRight:
                positionY = 0
            case .middleLeft, .middleCenter, .middleRight:
                positionY = Int((rect.height - innerPreferredSize.height) / 2)
            case .bottomLeft, .bottomCenter, .bottomRight:
                positionY = rect.height - innerPreferredSize.height
            }

            buffer.render(
                key: "Frame", view: inside, at: Point(x: positionX, y: positionY),
                clip: innerPreferredSize)
        },
        events: { event, buffer in
            buffer.events(key: "Frame", event: event, view: inside)
        }
    )
}
