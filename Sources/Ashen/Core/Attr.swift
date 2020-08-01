////
///  Attr.swift
//

import Termbox

extension View {
    public func styled(_ style: Attr) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { rect, buffer in
                self.render(rect, buffer)
                for y in (0..<rect.height) {
                    for x in (0..<rect.width) {
                        buffer.modifyCharacter(at: Point(x: x, y: y)) { c in
                            guard !c.attributes.contains(style) else { return c }
                            let newC = AttributedCharacter(
                                character: c.character, attributes: c.attributes + [style])
                            return newC
                        }
                    }
                }
            },
            events: events,
            key: key, id: id
        )
    }

    public func underlined() -> View<Msg> {
        styled(.underline)
    }

    public func bottomLined() -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { rect, buffer in
                self.render(rect, buffer)
                for x in (0..<rect.width) {
                    buffer.modifyCharacter(at: Point(x: x, y: rect.height - 1)) { c in
                        guard !c.attributes.contains(.underline) else { return c }
                        let newC = AttributedCharacter(
                            character: c.character, attributes: c.attributes + [.underline])
                        return newC
                    }
                }
            },
            events: events,
            key: key, id: id
        )
    }

    public func reversed() -> View<Msg> {
        styled(.reverse)
    }

    public func bold() -> View<Msg> {
        styled(.bold)
    }

    public func foreground(_ color: Color) -> View<Msg> {
        styled(.foreground(color))
    }

    public func background(_ color: Color) -> View<Msg> {
        styled(.background(color))
    }

    public func reset() -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { rect, buffer in
                self.render(rect, buffer)
                for x in (0..<rect.width) {
                    buffer.modifyCharacter(at: Point(x: x, y: rect.height - 1)) { $0.reset() }
                }
            },
            events: events,
            key: key, id: id
        )
    }
}

public enum Attr: Equatable {
    case underline
    case reverse
    case bold
    case foreground(Color)
    case background(Color)

    var toTermbox: TermboxAttributes {
        switch self {
        case .underline: return .underline
        case .reverse: return .reverse
        case .bold: return .bold
        case let .foreground(color): return color.toTermbox
        case let .background(color): return color.toTermbox
        }
    }

    public static func == (lhs: Attr, rhs: Attr) -> Bool {
        switch (lhs, rhs) {
        case (.underline, .underline):
            return true
        case (.reverse, .reverse):
            return true
        case (.bold, .bold):
            return true
        default:
            break
        }

        if case let .foreground(lhsColor) = lhs, case let .foreground(rhsColor) = rhs {
            return lhsColor == rhsColor
        }

        if case let .background(lhsColor) = lhs, case let .background(rhsColor) = rhs {
            return lhsColor == rhsColor
        }

        return false
    }
}
