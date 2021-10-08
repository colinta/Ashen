////
///  Frame.swift
//

public enum FrameOption {
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

private let NAME = "Frame"

public func Frame<Msg>(_ inside: View<Msg>, _ options: [FrameOption] = []) -> View<Msg> {
    var alignment: Alignment = .topCenter
    for opt in options {
        switch opt {
        case let .alignment(alignmentOpt):
            alignment = alignmentOpt
        }
    }

    return View<Msg>(
        preferredSize: { inside.preferredSize($0) },
        render: { viewport, buffer in
            guard !viewport.isEmpty else {
                buffer.render(key: .name(NAME), view: inside, viewport: .zero)
                return
            }

            let innerPreferredSize = inside.preferredSize(viewport.size)

            let positionX: Int
            let positionY: Int
            switch alignment {
            case .topLeft, .middleLeft, .bottomLeft:
                positionX = 0
            case .topCenter, .middleCenter, .bottomCenter:
                positionX = Int((viewport.size.width - innerPreferredSize.width) / 2)
            case .topRight, .middleRight, .bottomRight:
                positionX = viewport.size.width - innerPreferredSize.width
            }
            switch alignment {
            case .topLeft, .topCenter, .topRight:
                positionY = 0
            case .middleLeft, .middleCenter, .middleRight:
                positionY = Int((viewport.size.height - innerPreferredSize.height) / 2)
            case .bottomLeft, .bottomCenter, .bottomRight:
                positionY = viewport.size.height - innerPreferredSize.height
            }

            buffer.render(
                key: .name(NAME), view: inside,
                viewport: Viewport(
                    Rect(origin: Point(x: positionX, y: positionY), size: innerPreferredSize)))
        },
        events: { event, buffer in
            buffer.events(key: .name(NAME), event: event, view: inside)
        },
        debugName: NAME
    )
}
