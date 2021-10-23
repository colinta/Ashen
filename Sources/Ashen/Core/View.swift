////
///  View.swift
//

public struct View<Msg> {
    public let preferredSize: (Size) -> Size
    public let render: (LocalViewport, Buffer) -> Void
    public let events: (Event, Buffer) -> ([Msg], [Event])
    let viewKey: ViewKey?
    public let debugName: String

    public init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (LocalViewport, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event]),
        debugName: String = ""
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.viewKey = nil
        self.debugName = debugName
    }

    private init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (LocalViewport, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event]),
        viewKey: ViewKey?, debugName: String
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.viewKey = viewKey
        self.debugName = debugName
    }

    public static func scan(events: [Event], _ scan: (Event) -> ([Msg], [Event])) -> (
        [Msg], [Event]
    ) {
        events.reduce(([Msg](), [Event]())) { info, event in
            let (msgs, newEvents) = scan(event)
            return (info.0 + msgs, info.1 + newEvents)
        }
    }

    public static func scan(views: [View<Msg>], event: Event, buffer: Buffer) -> ([Msg], [Event]) {
        views.enumerated().reversed().reduce(([Msg](), [event])) { info, index_view in
            let (msgs, events) = info
            let (index, view) = index_view
            let (newMsgs, newEvents) = View.scan(events: events) { event in
                return buffer.events(key: .index(index), event: event, view: view)
            }
            return (msgs + newMsgs, newEvents)
        }
    }

    public func copy(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (LocalViewport, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event])
    ) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            viewKey: viewKey, debugName: debugName
        )
    }

    public func key(_ key: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            viewKey: .key(key), debugName: debugName
        )
    }

    public func id(_ id: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            viewKey: .id(id), debugName: debugName
        )
    }

    public func debugName(_ debugName: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            viewKey: viewKey,
            debugName: debugName
        )
    }

    public func map<U>(_ msgMap: @escaping (Msg) -> U) -> View<U> {
        View<U>(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                self.render(viewport, buffer)
            },
            events: { event, buffer in
                let (msgs, newEvents) = self.events(event, buffer)
                return (msgs.map(msgMap), newEvents)
            },
            viewKey: viewKey, debugName: debugName
        )
    }

    public func enableDebug() -> View<Msg> {
        View<Msg>(
            preferredSize: { size in
                let silenced = debugSilenced()
                debugSilenced(false)
                let preferredSize = self.preferredSize(size)
                debugSilenced(silenced)
                return preferredSize
            },
            render: { viewport, buffer in
                let silenced = debugSilenced()
                debugSilenced(false)
                self.render(viewport, buffer)
                debugSilenced(silenced)
            },
            events: { event, buffer in
                let silenced = debugSilenced()
                debugSilenced(false)
                let events = self.events(event, buffer)
                debugSilenced(silenced)
                return events
            },
            viewKey: viewKey, debugName: debugName
        )
    }

    public func background(view: View<Msg>) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                self.render(viewport, buffer)
                Repeating(view).render(viewport, buffer)
            },
            events: events,
            viewKey: viewKey, debugName: debugName + ".background(\(view.debugName))"
        )
    }

    public func modifyCharacters(
        _ modify: @escaping (Point, Size, AttributedCharacter) -> AttributedCharacter
    ) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let mask = buffer.mask
                self.render(viewport, buffer)
                let size = viewport.size
                for y in viewport.visible.minY..<viewport.visible.minY + viewport.visible.height {
                    for x in viewport.visible.minX..<viewport.visible.minX + viewport.visible.width
                    {
                        let pt = Point(x: x, y: y)
                        buffer.modifyCharacter(at: pt, mask: mask) { modify(pt, size, $0) }
                    }
                }
            },
            events: events,
            viewKey: viewKey, debugName: debugName
        )
    }
}

//
// MARK: View + Frame size extensions
//
extension View {
    public func minSize(_ constrainSize: Size) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size.max(preferredSize, constrainSize)
            },
            render: render,
            events: events,
            viewKey: viewKey, debugName: debugName + ".size(\(constrainSize))"
        )
    }

    public func size(_ constrainSize: Size) -> View<Msg> {
        View(
            preferredSize: { _ in constrainSize },
            render: render,
            events: events,
            viewKey: viewKey, debugName: debugName + ".size(\(constrainSize))"
        )
    }

    public func maxSize(_ constrainSize: Size) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size.min(preferredSize, constrainSize)
            },
            render: render,
            events: events,
            viewKey: viewKey, debugName: debugName + ".size(\(constrainSize))"
        )
    }

    public func minWidth(_ width: Int, fittingContainer: Bool = false) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                var newWidth = max(preferredSize.width, width)
                if fittingContainer {
                    newWidth = min(size.width, newWidth)
                }
                return Size(
                    width: newWidth,
                    height: preferredSize.height
                )
            },
            render: render,
            events: events,
            viewKey: viewKey, debugName: debugName + ".minWidth(\(width))"
        )
    }

    public func width(_ width: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: width,
                    height: preferredSize.height
                )
            },
            render: { viewport, buffer in
                let innerViewport = viewport.limit(width: width)
                buffer.push(viewport: innerViewport.toViewport()) {
                    self.render(innerViewport, buffer)
                }
            },
            events: events,
            viewKey: viewKey, debugName: debugName + ".width(\(width))"
        )
    }

    public func maxWidth(_ width: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: min(preferredSize.width, width),
                    height: preferredSize.height
                )
            },
            render: { viewport, buffer in
                let innerViewport = viewport.limit(width: width)
                buffer.push(viewport: innerViewport.toViewport()) {
                    self.render(innerViewport, buffer)
                }
            },
            events: events,
            viewKey: viewKey, debugName: debugName + ".maxWidth(\(width))"
        )
    }

    public func minHeight(_ height: Int, fittingContainer: Bool = false) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                var newHeight = max(preferredSize.height, height)
                if fittingContainer {
                    newHeight = min(size.height, newHeight)
                }
                return Size(
                    width: preferredSize.width,
                    height: newHeight
                )
            },
            render: render,
            events: events,
            viewKey: viewKey, debugName: debugName + ".minHeight(\(height))"
        )
    }

    public func height(_ height: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: preferredSize.width,
                    height: height
                )
            },
            render: { viewport, buffer in
                let innerViewport = viewport.limit(height: height)
                buffer.push(viewport: innerViewport.toViewport()) {
                    self.render(innerViewport, buffer)
                }
            },
            events: events,
            viewKey: viewKey, debugName: debugName + ".height(\(height))"
        )
    }

    public func maxHeight(_ height: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: preferredSize.width,
                    height: min(preferredSize.height, height)
                )
            },
            render: { viewport, buffer in
                let innerViewport = viewport.limit(height: height)
                buffer.push(viewport: innerViewport.toViewport()) {
                    self.render(innerViewport, buffer)
                }
            },
            events: events,
            viewKey: viewKey, debugName: debugName + ".maxHeight(\(height))"
        )
    }

    public func matchContainer(dimension: Dimension? = nil) -> View<Msg> {
        View(
            preferredSize: { parentSize in
                guard let dimension = dimension else { return parentSize }
                let preferredSize = self.preferredSize(parentSize)
                return Size(
                    width: dimension == .width ? parentSize.width : preferredSize.width,
                    height: dimension == .height ? parentSize.height : preferredSize.height
                )
            },
            render: render,
            events: events,
            viewKey: viewKey,
            debugName: debugName + ".matchContainer(\(dimension.map({ "\($0) "}) ?? ""))"
        )
    }

    public func matchSize(ofView: View<Msg>, dimension: Dimension? = nil) -> View<Msg> {
        View(
            preferredSize: { parentSize in
                let ofViewSize = ofView.preferredSize(parentSize)
                guard let dimension = dimension else { return ofViewSize }
                let preferredSize = self.preferredSize(parentSize)
                return Size(
                    width: dimension == .width ? ofViewSize.width : preferredSize.width,
                    height: dimension == .height ? ofViewSize.height : preferredSize.height
                )
            },
            render: render,
            events: events,
            viewKey: viewKey,
            debugName: debugName + ".matchContainer(of: \(ofView.debugName), \(dimension.map({ "\($0) "}) ?? ""))"
        )
    }

    public func shrink(_ dimension: Dimension, by: Int) -> View<Msg> {
        View(
            preferredSize: { parentSize in
                let preferredSize = self.preferredSize(parentSize)
                return Size(
                    width: dimension == .width ? preferredSize.width - by : preferredSize.width,
                    height: dimension == .height ? preferredSize.height - by : preferredSize.height
                )
            },
            render: render,
            events: events,
            viewKey: viewKey,
            debugName: debugName + ".shrink(\(dimension), by: \(by))"
        )
    }

    public func fitInContainer(dimension: Dimension? = nil) -> View<Msg> {
        View(
            preferredSize: { parentSize in
                let preferredSize = self.preferredSize(parentSize)
                return Size(
                    width: dimension == .width || dimension == nil
                        ? min(preferredSize.width, parentSize.width) : preferredSize.width,
                    height: dimension == .height || dimension == nil
                        ? min(preferredSize.height, parentSize.height) : preferredSize.height
                )
            },
            render: render,
            events: events,
            viewKey: viewKey,
            debugName: debugName + ".fitInContainer(\(dimension.map({ "\($0) "}) ?? ""))"
        )
    }

    public func compact() -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let size = self.preferredSize(viewport.size)
                let innerViewport = LocalViewport(
                    size: size, visible: viewport.visible)
                self.render(innerViewport, buffer)
            },
            events: events,
            viewKey: viewKey, debugName: debugName + ".compact()"
        )
    }

    public func offset(_ point: Point) -> View<Msg> {
        offset(x: point.x, y: point.y)
    }

    public func offset(x: Int, y: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: preferredSize.width + x,
                    height: preferredSize.height + y
                )
            },
            render: { viewport, buffer in
                let innerSize = viewport.size.shrink(width: x, height: y)
                let innerViewport = Viewport(Rect(origin: Point(x: x, y: y), size: innerSize))
                buffer.push(viewport: innerViewport) {
                    self.render(innerViewport.toLocalViewport(), buffer)
                }
            },
            events: events,
            viewKey: viewKey,
            debugName: debugName
                + """
                .padding(\([
                    y != 0 ? "y: \(y)" : nil,
                    x != 0 ? "x: \(x)" : nil,
                ].compactMap({ $0 }).joined(separator: ", ")))
                """
        )
    }
    public func padding(_ insets: Insets) -> View<Msg> {
        padding(top: insets.top, left: insets.left, bottom: insets.bottom, right: insets.right)
    }

    public func padding(top: Int = 0, left: Int = 0, bottom: Int = 0, right: Int = 0) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: preferredSize.width + left + right,
                    height: preferredSize.height + top + bottom
                )
            },
            render: { viewport, buffer in
                let innerSize = viewport.size.shrink(
                    width: left + right, height: top + bottom)
                let innerViewport = Viewport(Rect(origin: Point(x: left, y: top), size: innerSize))
                buffer.push(viewport: innerViewport) {
                    self.render(innerViewport.toLocalViewport(), buffer)
                }
            },
            events: events,
            viewKey: viewKey,
            debugName: debugName
                + """
                .padding(\([
                    top != 0 ? "top: \(top)" : nil,
                    left != 0 ? "left: \(left)" : nil,
                    bottom != 0 ? "bottom: \(bottom)" : nil,
                    right != 0 ? "right: \(right)" : nil,
                ].compactMap({ $0 }).joined(separator: ", ")))
                """
        )
    }
}

//
// MARK: View + Attr extensions
//
extension View {
    public func styled(_ style: Attr, preserve: Bool = false) -> View<Msg> {
        styled([style], preserve: preserve)
    }

    public func styled(_ styles: [Attr], preserve: Bool = false) -> View<Msg> {
        copy(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let mask = buffer.mask
                self.render(viewport, buffer)
                for y in (0..<viewport.size.height) {
                    for x in (0..<viewport.size.width) {
                        buffer.modifyCharacter(at: Point(x: x, y: y), mask: mask) { c in
                            let attributes = preserve
                                ? styles + c.attributes
                                : c.attributes + styles
                            return AttributedCharacter(
                                character: c.character, attributes: attributes)
                        }
                    }
                }
            },
            events: events
        )
    }

    public func underlined() -> View<Msg> {
        styled(.underline)
    }

    public func bottomLined() -> View<Msg> {
        copy(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let mask = buffer.mask
                self.render(viewport, buffer)
                for x in (0..<viewport.size.width) {
                    buffer.modifyCharacter(
                        at: Point(x: x, y: viewport.size.height - 1), mask: mask
                    ) { c in
                        guard !c.attributes.contains(.underline) else { return c }
                        let newC = AttributedCharacter(
                            character: c.character, attributes: c.attributes + [.underline])
                        return newC
                    }
                }
            },
            events: events
        )
    }

    public func reversed() -> View<Msg> {
        styled(.reverse)
    }

    public func bold() -> View<Msg> {
        styled(.bold)
    }

    public func foreground(color: Color) -> View<Msg> {
        styled(.foreground(color))
    }

    public func background(color: Color) -> View<Msg> {
        styled(.background(color))
    }

    public func defaultBackground(color: Color) -> View<Msg> {
        return styled(.background(color), preserve: true)
    }

    public func reset() -> View<Msg> {
        copy(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let mask = buffer.mask
                self.render(viewport, buffer)
                for x in (0..<viewport.size.width) {
                    buffer.modifyCharacter(
                        at: Point(x: x, y: viewport.size.height - 1), mask: mask
                    ) {
                        $0.reset()
                    }
                }
            },
            events: events
        )
    }
}
