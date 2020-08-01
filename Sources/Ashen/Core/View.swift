////
///  View.swift
//

public struct View<Msg> {
    let preferredSize: (Size) -> Size
    let render: (Rect, Buffer) -> Void
    let events: (Event, Buffer) -> ([Msg], [Event])
    let key: String?
    let id: String?

    init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (Rect, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event])
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.key = nil
        self.id = nil
    }

    init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (Rect, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event]),
        key: String
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.key = key
        self.id = nil
    }

    init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (Rect, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event]),
        id: String
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.key = nil
        self.id = id
    }

    init(
        preferredSize: @escaping (Size) -> Size,
        render: @escaping (Rect, Buffer) -> Void,
        events: @escaping (Event, Buffer) -> ([Msg], [Event]),
        key: String?, id: String?
    ) {
        self.preferredSize = preferredSize
        self.render = render
        self.events = events
        self.key = key
        self.id = id
    }

    public static func scan(events: [Event], _ scan: (Event) -> ([Msg], [Event])) -> (
        [Msg], [Event]
    ) {
        events.reduce(([Msg](), [Event]())) { info, event in
            let (msgs, newEvents) = scan(event)
            return (info.0 + msgs, info.1 + newEvents)
        }
    }

    public func key(_ key: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            key: key
        )
    }

    public func id(_ id: String) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: render,
            events: events,
            id: id
        )
    }

    public func map<U>(_ msgMap: @escaping (Msg) -> U) -> View<U> {
        View<U>(
            preferredSize: preferredSize,
            render: { rect, buffer in
                self.render(rect, buffer)
            },
            events: { event, buffer in
                let (msgs, newEvents) = self.events(event, buffer)
                return (msgs.map(msgMap), newEvents)
            }
        )
    }

    public func minWidth(_ width: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: max(parent.width, width),
                    height: parent.height
                )
            },
            render: render,
            events: events,
            key: key, id: id
        )
    }

    public func width(_ width: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: width,
                    height: parent.height
                )
            },
            render: render,
            events: events,
            key: key, id: id
        )
    }

    public func maxWidth(_ width: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: min(parent.width, width),
                    height: parent.height
                )
            },
            render: render,
            events: events,
            key: key, id: id
        )
    }

    public func minHeight(_ height: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: parent.width,
                    height: max(parent.height, height)
                )
            },
            render: render,
            events: events,
            key: key, id: id
        )
    }

    public func height(_ height: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: parent.width,
                    height: height
                )
            },
            render: render,
            events: events,
            key: key, id: id
        )
    }

    public func maxHeight(_ height: Int) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: parent.width,
                    height: min(parent.height, height)
                )
            },
            render: render,
            events: events,
            key: key, id: id
        )
    }

    public func padding(top: Int = 0, left: Int = 0, bottom: Int = 0, right: Int = 0) -> View<Msg> {
        View(
            preferredSize: { size in
                let parent = self.preferredSize(size)
                return Size(
                    width: parent.width + left + right,
                    height: parent.height + top + bottom
                )
            },
            render: { rect, buffer in
                let innerSize = rect.size.shrink(width: left + right, height: top + bottom)
                buffer.push(at: Point(x: left, y: top), clip: innerSize) {
                    let innerRect = Rect(origin: .zero, size: innerSize)
                    self.render(innerRect, buffer)
                }
            },
            events: events,
            key: key, id: id
        )
    }

    public func modifyCharacters(
        _ modify: @escaping (Point, Size, AttributedCharacter) -> AttributedCharacter
    ) -> View<Msg> {
        View(
            preferredSize: preferredSize,
            render: { rect, buffer in
                self.render(rect, buffer)
                let size = rect.size
                for y in rect.origin.y..<rect.origin.y + rect.height {
                    for x in rect.origin.x..<rect.origin.x + rect.width {
                        let pt = Point(x: x, y: y)
                        buffer.modifyCharacter(at: pt) { modify(pt, size, $0) }
                    }
                }
            },
            events: events,
            key: key, id: id
        )
    }
}
