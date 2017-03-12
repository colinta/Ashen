////
///  BlackBoxGame.swift
//

import Darwin

private func rand(min: Int = 0, lessThan: Int) -> Int {
    guard lessThan != min else { return min }
    guard lessThan > min else { return rand(min: lessThan, lessThan: min) }
    return min + Int(arc4random_uniform(UInt32(lessThan - min)))
}


struct BlackBoxGame: Program {
    enum Message {
        case quit
        case fire
        case new
        case showAnswer
        case moveUp
        case moveDown
        case moveLeft
        case moveRight
    }

    struct Board {
        let size: Size
        let atoms: [Point]
        var guesses: [Point] = []
        var rays: [(Cursor, Cursor?)]
        var maxX: Int { return size.width - 1 }
        var maxY: Int { return size.height - 1 }

        init(width: Int, height: Int, atomsCount: Int) {
            size = Size(width: width, height: height)
            atoms = (0 ..< atomsCount).reduce([Point]()) { memo, _ in
                while true {
                    let p = Point(x: rand(lessThan: width), y: rand(lessThan: height))
                    if !memo.contains(p) { return memo + [p] }
                }
            }
            rays = []
        }
    }

    enum Cursor {
        enum StringStyle {
            case rayIn
            case rayOut
            case rayInOut

            var chars: [String] {
                switch self {
                case .rayIn: return ["→","←","↓","↑","_"]
                case .rayOut: return ["←","→","↑","↓","_"]
                case .rayInOut: return ["⇄","⇄","⇵","⇵","_"]
                }
            }
        }

        case left(y: Int)
        case right(y: Int)
        case top(x: Int)
        case bottom(x: Int)
        case inside(Int, Int)

        func text(_ style: StringStyle) -> String {
            switch self {
            case .left:   return style.chars[0]
            case .right:  return style.chars[1]
            case .top:    return style.chars[2]
            case .bottom: return style.chars[3]
            case .inside: return style.chars[4]
            }
        }
    }

    struct Model {
        var board: Board
        var cursor: Cursor
        var showAtomLocations: Bool
    }

    func setup(screen: ScreenType) {
        screen.initColor(1, fg: (0, 1000, 0), bg: nil)
        screen.initColor(2, fg: nil, bg: (0, 1000, 0))
    }

    func initial() -> (Model, [Command]) {
        return (Model(
            board: Board(width: 10, height: 5, atomsCount: rand(min: 3, lessThan: 7)),
            cursor: .left(y: 0),
            showAtomLocations: false
            ), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case .showAnswer:
            model.showAtomLocations = true
        case .new:
            model.board = Board(width: 10, height: 5, atomsCount: rand(min: 3, lessThan: 7))
            model.showAtomLocations = false
        case .fire:
            if !model.showAtomLocations {
                if case let .inside(x, y) = model.cursor {
                    model.board.toggleGuess(Point(x: x, y: y))
                }
                else {
                    model.board.fire(model.cursor)
                }
            }
        case .moveUp:
            switch model.cursor {
            case .top:
                break
            case .left(y: 0):
                model.cursor = .top(x: 0)
            case .right(0):
                model.cursor = .top(x: model.board.maxX)
            case let .left(y):
                model.cursor = .left(y: y - 1)
            case let .right(y):
                model.cursor = .right(y: y - 1)
            case let .bottom(x):
                model.cursor = .inside(x, model.board.maxY)
            case let .inside(x, 0):
                model.cursor = .top(x: x)
            case let .inside(x, y):
                model.cursor = .inside(x, y - 1)
            }
        case .moveDown:
            switch model.cursor {
            case .bottom:
                break
            case .left(y: model.board.maxY):
                model.cursor = .bottom(x: 0)
            case .right(model.board.maxY):
                model.cursor = .bottom(x: model.board.maxX)
            case let .left(y):
                model.cursor = .left(y: y + 1)
            case let .right(y):
                model.cursor = .right(y: y + 1)
            case let .top(x):
                model.cursor = .inside(x, 0)
            case let .inside(x, model.board.maxY):
                model.cursor = .bottom(x: x)
            case let .inside(x, y):
                model.cursor = .inside(x, y + 1)
            }
        case .moveLeft:
            switch model.cursor {
            case .left:
                break
            case .top(x: 0):
                model.cursor = .left(y: 0)
            case .bottom(x: 0):
                model.cursor = .left(y: model.board.maxY)
            case let .top(x):
                model.cursor = .top(x: x - 1)
            case let .bottom(x):
                model.cursor = .bottom(x: x - 1)
            case let .right(y):
                model.cursor = .inside(model.board.maxX, y)
            case let .inside(0, y):
                model.cursor = .left(y: y)
            case let .inside(x, y):
                model.cursor = .inside(x - 1, y)
            }
        case .moveRight:
            switch model.cursor {
            case .right:
                break
            case .top(x: model.board.maxX):
                model.cursor = .right(y: 0)
            case .bottom(x: model.board.maxX):
                model.cursor = .right(y: model.board.maxY)
            case let .top(x):
                model.cursor = .top(x: x + 1)
            case let .bottom(x):
                model.cursor = .bottom(x: x + 1)
            case let .left(y):
                model.cursor = .inside(0, y)
            case let .inside(model.board.maxX, y):
                model.cursor = .right(y: y)
            case let .inside(x, y):
                model.cursor = .inside(x + 1, y)
            }
        case .quit:
            return (model, [], .quit)
        }
        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        let outerBoxSize = Size(
            width: model.board.size.width + 4,
            height: model.board.size.height + 4
            )
        let innerBoxSize = Size(
            width: model.board.size.width + 2,
            height: model.board.size.height + 2
            )

        let location: Location = model.board.location(of: model.cursor)
        let cursorLabel = LabelView(location, text: Text(" "))
        let cursorAttr = LabelView(location, text: Text(nil, attrs: [.reverse]))

        let rayLabels: [Component] = model.board.rays.enumerated().flatMap { (index, cursors) -> [LabelView] in
            let (startCursor, destCursor) = cursors
            let attrs: [Attr]
            if startCursor == model.cursor || destCursor == model.cursor {
                attrs = [.color(2)]
            }
            else {
                attrs = [.color(1)]
            }
            if startCursor == destCursor {
                let location = model.board.location(of: startCursor)
                let text = startCursor.text(.rayInOut)
                return [LabelView(location, text: Text(text, attrs: attrs))]
            }
            else if let destCursor = destCursor {
                return [
                    LabelView(model.board.location(of: startCursor), text: Text(startCursor.text(.rayIn), attrs: attrs)),
                    LabelView(model.board.location(of: destCursor), text: Text(destCursor.text(.rayOut), attrs: attrs)),
                ]
            }
            else {
                let location = model.board.location(of: startCursor)
                let text = startCursor.text(.rayIn)
                return [LabelView(location, text: Text(text, attrs: attrs))]
            }
        }
        let guessLabels: [Component] = model.board.guesses.map { guess in
            let location = model.board.location(of: .inside(guess.x, guess.y))
            let text: String
            if model.showAtomLocations && model.board.atoms.contains(guess) {
                text = "●"
            }
            else if model.showAtomLocations {
                text = "×"
            }
            else {
                text = "○"
            }
            return LabelView(location, text: text)
        }

        let atomLocations: [Component]
        if model.showAtomLocations {
            atomLocations = model.board.atoms.map { atomPosition in
                let location = model.board.location(of: .inside(atomPosition.x, atomPosition.y))
                return LabelView(location, text: "*")
            }
        }
        else {
            atomLocations = []
        }
        let innerBox = Box(.topLeft(x: 1, y: 1), innerBoxSize, border: .bold, background: ".")
        let outerBox = Box(.middleCenter(), outerBoxSize, components: [innerBox, cursorLabel] + atomLocations + rayLabels + guessLabels + [cursorAttr])

        return Window(
            components: [
                outerBox,
                OnKeyPress(.key_up, { return Message.moveUp }),
                OnKeyPress(.key_down, { return Message.moveDown }),
                OnKeyPress(.key_left, { return Message.moveLeft }),
                OnKeyPress(.key_right, { return Message.moveRight }),
                OnKeyPress(.key_enter, { return Message.quit }),
                OnKeyPress(.key_space, { return Message.fire }),
                OnKeyPress(.symbol_star, { return Message.new }),
                OnKeyPress(.symbol_question, { return Message.showAnswer }),
            ])
    }
}

extension BlackBoxGame.Cursor: Equatable {
    static func == (lhs: BlackBoxGame.Cursor, rhs: BlackBoxGame.Cursor) -> Bool {
        switch (lhs, rhs) {
        case let (.left(lhs_y), .left(rhs_y)):
            return lhs_y == rhs_y
        case let (.right(lhs_y), .right(rhs_y)):
            return lhs_y == rhs_y
        case let (.top(lhs_x), .top(rhs_x)):
            return lhs_x == rhs_x
        case let (.bottom(lhs_x), .bottom(rhs_x)):
            return lhs_x == rhs_x
        case let (.inside(lhs_x, lhs_y), .inside(rhs_x, rhs_y)):
            return lhs_x == rhs_x && lhs_y == rhs_y
        default:
            return false
        }
    }
}

extension BlackBoxGame.Board {
    private func atomAt(_ point: Point) -> Bool {
        return nil != atoms.index(where: { atom in
            return atom.x == point.x && atom.y == point.y
        })
    }

    private func turnLeft(_ point: Point) -> Point {
        if point.x > 0 { return Point(x: 0, y: -point.x) }
        if point.x < 0 { return Point(x: 0, y: point.x) }
        if point.y > 0 { return Point(x: point.y, y: 0) }
        if point.y < 0 { return Point(x: -point.y, y: 0) }
        return point
    }

    private func turnRight(_ point: Point) -> Point {
        if point.x > 0 { return Point(x: 0, y: point.x) }
        if point.x < 0 { return Point(x: 0, y: -point.x) }
        if point.y > 0 { return Point(x: -point.y, y: 0) }
        if point.y < 0 { return Point(x: point.y, y: 0) }
        return point
    }

    mutating func fire(_ startCursor: BlackBoxGame.Cursor) {
        guard nil == rays.index(where: { (c1, c2) in
            return c1 == startCursor || c2 == startCursor
        }) else { return }

        var current: Point
        var direction: Point
        switch startCursor {
        case let .left(y):
            current = Point(x: -1, y: y)
            direction = Point(x: 1, y: 0)
        case let .right(y):
            current = Point(x: maxX + 1, y: y)
            direction = Point(x: -1, y: 0)
        case let .top(x):
            current = Point(x: x, y: -1)
            direction = Point(x: 0, y: 1)
        case let .bottom(x):
            current = Point(x: x, y: maxY + 1)
            direction = Point(x: 0, y: -1)
        default:
            return
        }

        var destCursor: BlackBoxGame.Cursor? = nil
        var first = true
        while destCursor == nil {
            let nextPoint = Point(
                x: current.x + direction.x,
                y: current.y + direction.y
                )
            if atomAt(nextPoint) {
                break }

            let nextLeftDirection = turnLeft(direction)
            let nextRightDirection = turnRight(direction)
            let nextLeft = Point(
                x: nextPoint.x + nextLeftDirection.x,
                y: nextPoint.y + nextLeftDirection.y
                )
            let nextRight = Point(
                x: nextPoint.x + nextRightDirection.x,
                y: nextPoint.y + nextRightDirection.y
                )

            let atomAtLeft = atomAt(nextLeft)
            let atomAtRight = atomAt(nextRight)
            if (first && (atomAtLeft || atomAtRight)) || (atomAtLeft && atomAtRight) {
                destCursor = startCursor
            }
            else if atomAtLeft {
                current = Point(
                    x: current.x + nextRightDirection.x,
                    y: current.y + nextRightDirection.y
                    )
                direction = nextRightDirection
            }
            else if atomAtRight {
                current = Point(
                    x: current.x + nextLeftDirection.x,
                    y: current.y + nextLeftDirection.y
                    )
                direction = nextLeftDirection
            }
            else {
                current = Point(
                    x: current.x + direction.x,
                    y: current.y + direction.y
                    )
            }

            if current.x < 0 {
                destCursor = .left(y: current.y)
            }
            else if current.x > maxX {
                destCursor = .right(y: current.y)
            }
            else if current.y < 0 {
                destCursor = .top(x: current.x)
            }
            else if current.y > maxX {
                destCursor = .bottom(x: current.x)
            }
            first = false
        }

        rays.append((startCursor, destCursor))
    }

    func location(of cursor: BlackBoxGame.Cursor) -> Location {
        let minX = 2
        let maxX = minX + self.maxX
        let minY = 2
        let maxY = minY + self.maxY
        switch cursor {
        case let .left(y):
            return .topLeft(x: minX - 2, y: minY + y)
        case let .right(y):
            return .topLeft(x: maxX + 2, y: minY + y)
        case let .top(x):
            return .topLeft(x: minX + x, y: minY - 2)
        case let .bottom(x):
            return .topLeft(x: minX + x, y: maxY + 2)
        case let .inside(x, y):
            return .topLeft(x: minX + x, y: minY + y)
        }
    }

    mutating func toggleGuess(_ nextGuess: Point) {
        var removed = false
        guesses = guesses.flatMap { (guess: Point) -> Point? in
            if !removed && guess.x == nextGuess.x && guess.y == nextGuess.y {
                removed = true
                return nil
            }
            return guess
        } + (removed ? [] : [nextGuess])
    }
}
