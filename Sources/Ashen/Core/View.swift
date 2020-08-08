////
///  View.swift
//

public struct View<Msg> {
    public let preferredSize: (Size) -> Size
    public let render: (LocalViewport, Buffer) -> Void
    public let events: (Event, Buffer) -> ([Msg], [Event])
    let key: String?
    let id: String?
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
        self.key = nil
        self.id = nil
        self.debugName = debugName
    }

    private init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (LocalViewport, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event]),
        key: String?, id: String?, debugName: String
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.key = key
        self.id = id
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
        views.enumerated().reduce(([Msg](), [event])) { info, index_view in
            let (msgs, events) = info
            let (index, view) = index_view
            let (newMsgs, newEvents) = View.scan(events: events) { event in
                return buffer.events(key: index, event: event, view: view)
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
            key: key, id: id, debugName: debugName
        )
    }

    public func key(_ key: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            key: key, id: nil, debugName: debugName
        )
    }

    public func id(_ id: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            key: nil, id: id, debugName: debugName
        )
    }

    public func debugName(_ debugName: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            key: key,
            id: id,
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
            key: key, id: id, debugName: debugName
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
            key: key, id: id, debugName: debugName + ".background(\(view.debugName))"
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
                for y in viewport.mask.minY..<viewport.mask.minY + viewport.mask.height {
                    for x in viewport.mask.minX..<viewport.mask.minX + viewport.mask.width {
                        let pt = Point(x: x, y: y)
                        buffer.modifyCharacter(at: pt, mask: mask) { modify(pt, size, $0) }
                    }
                }
            },
            events: events,
            key: key, id: id, debugName: debugName
        )
    }
}

//
// MARK: View + Frame size extensions
//
extension View {
    public func size(_ size: Size) -> View<Msg> {
        View(
            preferredSize: { _ in
                return size
            },
            render: render,
            events: events,
            key: key, id: id, debugName: debugName + ".size(\(size))"
        )
    }

    public func minWidth(_ width: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: max(preferredSize.width, width),
                    height: preferredSize.height
                )
            },
            render: render,
            events: events,
            key: key, id: id, debugName: debugName + ".minWidth(\(width))"
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
            key: key, id: id, debugName: debugName + ".width(\(width))"
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
            key: key, id: id, debugName: debugName + ".maxWidth(\(width))"
        )
    }

    public func minHeight(_ height: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let preferredSize = self.preferredSize(size)
                return Size(
                    width: preferredSize.width,
                    height: max(preferredSize.height, height)
                )
            },
            render: render,
            events: events,
            key: key, id: id, debugName: debugName + ".minHeight(\(height))"
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
            key: key, id: id, debugName: debugName + ".height(\(height))"
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
            key: key, id: id, debugName: debugName + ".maxHeight(\(height))"
        )
    }

    public func matchParent(_ dimension: Dimension) -> View<Msg> {
        View(
            preferredSize: { parentSize in
                let preferredSize = self.preferredSize(parentSize)
                return Size(
                    width: dimension == .width ? parentSize.width : preferredSize.width,
                    height: dimension == .height ? parentSize.height : preferredSize.height
                )
            },
            render: render,
            events: events,
            key: key, id: id, debugName: debugName + ".matchParent(\(dimension))"
        )
    }

    public func fitInParent(_ dimension: Dimension) -> View<Msg> {
        View(
            preferredSize: { parentSize in
                let preferredSize = self.preferredSize(parentSize)
                return Size(
                    width: dimension == .width
                        ? min(preferredSize.width, parentSize.width) : preferredSize.width,
                    height: dimension == .height
                        ? min(preferredSize.height, parentSize.height) : preferredSize.height
                )
            },
            render: render,
            events: events,
            key: key, id: id, debugName: debugName + ".fitInParent(\(dimension))"
        )
    }

    public func compact() -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let size = self.preferredSize(viewport.size)
                let innerViewport = LocalViewport(
                    size: size, mask: viewport.mask)
                self.render(innerViewport, buffer)
            },
            events: events,
            key: key, id: id, debugName: debugName + ".compact()"
        )
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
            key: key, id: id,
            debugName: debugName
                + ".padding(top: \(top), left: \(left), bottom: \(bottom), right: \(right))"
        )
    }
}

//
// MARK: View + Attr extensions
//
extension View {
    public func styled(_ style: Attr) -> View<Msg> {
        copy(
            preferredSize: preferredSize,
            render: { viewport, buffer in
                let mask = buffer.mask
                self.render(viewport, buffer)
                for y in (0..<viewport.size.height) {
                    for x in (0..<viewport.size.width) {
                        buffer.modifyCharacter(at: Point(x: x, y: y), mask: mask) { c in
                            guard !c.attributes.contains(style) else { return c }
                            let newC = AttributedCharacter(
                                character: c.character, attributes: c.attributes + [style])
                            return newC
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
