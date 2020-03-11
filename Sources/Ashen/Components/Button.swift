////
///  Button.swift
//

public class Button: ComponentView {
    public typealias OnClickHandler = (() -> AnyMessage)
    let size: DesiredSize?
    let content: ComponentView
    var onClick: OnClickHandler
    var clickState: ClickState = .up

    enum ClickState {
        case up
        case down
        case ignore
    }

    public init(
        at location: Location = .tl(.zero),
        size: DesiredSize? = nil,
        onClick: @escaping OnClickHandler,
        content: ComponentView
    ) {
        self.size = size
        self.content = content
        self.onClick = onClick
        super.init()
        self.location = location
    }

    override public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let component = self

        let myClick = self.onClick
        let onClick: OnClickHandler = {
            return mapper(myClick() as! T)
        }
        component.onClick = onClick

        return component
    }

    override public func merge(with prevComponent: Component) {
        guard let prevInput = prevComponent as? Button else { return }

        clickState = prevInput.clickState
    }

    override public func desiredSize() -> DesiredSize {
        if let size = size { return size }

        let desiredSize = size ?? content.desiredSize()
        let width: Dimension?
        switch desiredSize.width {
        case let .some(.literal(val)):
            width = .literal(val + 1)
        default:
            width = desiredSize.width
        }
        let height: Dimension?
        switch desiredSize.height {
        case let .some(.literal(val)):
            height = .literal(val + 1)
        default:
            height = desiredSize.height
        }
        return DesiredSize(width: width, height: height)
    }

    override public func render(to buffer: Buffer, in rect: Rect) {
        buffer.claimMouse(rect: rect, component: self)

        if clickState == .down {
            buffer.push(offset: Point(x: 1, y: 1), clip: rect.size - Size(width: 1, height: 1)) {
                content.render(to: buffer, in: rect - Size(width: 1, height: 1))
            }
        }
        else {
            content.render(to: buffer, in: rect - Size(width: 1, height: 1))
        }
    }

    override public func messages(for event: Event) -> [AnyMessage] {
        guard
            case let .mouse(mouse) = event,
            mouse.component === self
        else { return [] }

        var retVal: [AnyMessage] = []
        switch mouse.event {
        case .click(.left):
            clickState = .down
            retVal = [SystemMessage.rerender]
        case .release(.left):
            if clickState == .down {
                retVal = [onClick(), SystemMessage.rerender]
            }
            else {
                retVal = [SystemMessage.rerender]
            }
            clickState = .up
        default:
            clickState = .ignore
        }

        return retVal
    }
}
