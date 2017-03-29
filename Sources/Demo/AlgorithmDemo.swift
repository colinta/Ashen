////
///  AlgorithmDemo.swift
//

import Darwin


struct AlgorithmDemo: Program {
    enum Message {
        case reset
        case start
        case nextFocus
        case textChanged(Int, String)
        case progress(String)
        case complete([Text])
    }

    struct Model {
        var focus: Int
        var a: String
        var b: String
        var started: Bool
        var progress: [String]
        var result: [Text]?
    }

    func initial() -> (Model, [Command]) {
        return (Model(focus: 0, a: "", b: "", started: false, progress: [], result: nil), [])
    }

    func update(model: inout Model, message: Message)
        -> (Model, [Command], LoopState)
    {
        switch message {
        case let .progress(progress):
            model.progress.append(progress)
        case let .complete(complete):
            model.result = complete
        case .nextFocus:
            model.focus = (model.focus + 1) % 2
        case .start:
            let commands: [Command]
            if !model.started {
                model.started = true
                let cmd = AlgorithmCommand<String>(a: model.a.characters.map { String($0) }, b: model.b.characters.map { String($0) })
                cmd.onIter = { desc in
                    return Message.progress(desc)
                }
                cmd.onDone = { diffs in
                    return Message.complete(diffs.map { $0.draw() })
                }
                commands = [cmd]
            }
            else {
                commands = []
            }
            return (model, commands, .continue)
        case let .textChanged(index, text):
            switch index {
                case 0: model.a = text
                case 1: model.b = text
                default: break
            }
        case .reset:
            model = Model(focus: 0, a: model.a, b: model.b, started: false, progress: [], result: nil)
        }
        return (model, [], .continue)
    }

    func render(model: Model, in screenSize: Size) -> Component {
        var components: [Component] = []
        if model.started {
            components.append(LabelView(.topLeft(y: 0), text: model.a))
            components.append(LabelView(.topLeft(y: 1), text: model.b))
            if let result = model.result {
                var y = 2
                for text in result {
                    components.append(LabelView(.topLeft(y: y), text: text))
                    y += 1
                }
            }
            else if let desc = model.progress.last {
                components.append(LabelView(.topLeft(y: 2), text: desc))
            }
            components.append(OnKeyPress(.key_enter, { return Message.reset }))
        }
        else {
            components.append(InputView(.topLeft(y: 0), text: model.a, isFirstResponder: model.focus == 0, onChange: { Message.textChanged(0, $0) }))
            components.append(InputView(.topLeft(y: 1), text: model.b, isFirstResponder: model.focus == 1, onChange: { Message.textChanged(1, $0) }))
            components.append(OnKeyPress(.key_tab, { return Message.nextFocus }))
            components.append(OnKeyPress(.key_enter, { return Message.start }))
        }

        return Window(
            components: components)
    }
}


enum SimpleDiff {
    case same
    case insert
    case delete
}

indirect enum Diff<T> {
    case seq([Diff<T>])
    case same(T)
    case insert(T)
    case delete(T)

    func equals(_ diff: SimpleDiff) -> Bool {
        switch (self, diff) {
        case (.same, .same): return true
        case (.insert, .insert): return true
        case (.delete, .delete): return true
        default: return false
        }
    }

    var simple: SimpleDiff? {
        switch self {
        case .same: return .same
        case .insert: return .insert
        case .delete: return .delete
        default: return nil
        }
    }

    var score: Float {
        switch self {
        case .same: return sqrt(2)
        case .insert: return 1
        case .delete: return 1
        case let .seq(seq):
            var score: Float = 0
            for diff in seq {
                switch diff {
                case .same:
                    score += sqrt(2)
                case .insert, .delete:
                    score += 1
                case .seq:
                    score += diff.score
                }
            }
            return score
        }
    }

    func draw() -> Text {
        switch self {
        case let .delete(a): return Text("-\(a)", attrs: [.color(1)])
        case let .insert(b): return Text("+\(b)", attrs: [.color(2)])
        case let .same(ab): return Text(" \(ab)")
        case let .seq(seq):
            return Text(seq.map({ $0.draw().text ?? "" }).joined(separator: ""))
        }
    }

}


class AlgorithmCommand<T: Equatable>: Command {
    let a: [T], b: [T]

    var onDone: (([Diff<T>]) -> AnyMessage)?
    var onIter: ((String) -> AnyMessage)?

    init(a: [T], b: [T]) {
        self.a = a
        self.b = b
    }

    func start(_ done: @escaping (AnyMessage) -> Void) {
        let diff = compare(done)
        onDone.map { done($0(diff)) }
    }

    func compare(_ done: @escaping (AnyMessage) -> Void) -> [Diff<T>] {
        guard a.count > 0 && b.count > 0 else { return [] }
        guard a.count > 0 else { return b.map { .insert($0) } }
        guard b.count > 0 else { return a.map { .delete($0) } }
        guard a != b else { return a.map { .same($0) } }

        var nodes: [Node<T>] = [Node(at: (-1, -1))]
        while nodes.count > 0 {
            nodes.sort() { n1, n2 in
                let score1 = n1.score + sqrt(pow(Float(a.count - n1.indices.a), 2) + pow(Float(b.count - n1.indices.b), 2))
                let score2 = n2.score + sqrt(pow(Float(a.count - n2.indices.a), 2) + pow(Float(b.count - n2.indices.b), 2))
                return score1 < score2
            }
            let currentNode = nodes.removeFirst()

            if currentNode.indices.a == a.count - 1 && currentNode.indices.b == b.count - 1 {
                return currentNode.seq
            }
            onIter.map { done($0(currentNode.desc)) }

            var candidates: [Node<T>] = []

            let candidateDelete: T? = currentNode.indices.a + 1 < a.count ? a[currentNode.indices.a + 1] : nil
            let candidateInsert: T? = currentNode.indices.b + 1 < b.count ? b[currentNode.indices.b + 1] : nil
            if let candidateDelete = candidateDelete, let candidateInsert = candidateInsert, candidateDelete == candidateInsert {
                candidates.append(Node(.same(candidateInsert), at: (currentNode.indices.a + 1, currentNode.indices.b + 1), parent: currentNode))
            }
            else {
                if let candidateDelete = candidateDelete {
                    var valid = true
                    if currentNode.diff?.equals(.insert) == true, currentNode.any(parentIs: .delete) {
                        valid = false
                    }

                    if valid {
                        candidates.append(Node(.delete(candidateDelete), at: (currentNode.indices.a + 1, currentNode.indices.b), parent: currentNode))
                    }
                }

                if let candidateInsert = candidateInsert {
                    var valid = true
                    if currentNode.diff?.equals(.delete) == true, currentNode.any(parentIs: .insert) {
                        valid = false
                    }

                    if valid {
                        candidates.append(Node(.insert(candidateInsert), at: (currentNode.indices.a, currentNode.indices.b + 1), parent: currentNode))
                    }
                }
            }

            var added: [Node<T>] = []
            for candidate in candidates {
                var add = true
                for (nodeIndex, node) in nodes.enumerated() {
                    if candidate.indices.a == node.indices.a && candidate.indices.b == node.indices.b {
                        if candidate.score < node.score {
                            nodes.remove(at: nodeIndex)
                        }
                        else {
                            add = false
                        }
                        break
                    }
                }
                if add {
                    added.append(candidate)
                }
            }
            nodes += added
        }
        return []
    }

    func map<From, To>(_ mapper: @escaping (From) -> To) -> Self {
        let command = self

        if let myDone = self.onDone {
            let onDone: ([Diff<T>]) -> To = { result in
                return mapper(myDone(result) as! From)
            }
            command.onDone = onDone
        }

        if let myIter = self.onIter {
            let onIter: (String) -> To = { result in
                return mapper(myIter(result) as! From)
            }
            command.onIter = onIter
        }

        return command
    }
}

class Node<T> {
    var diff: Diff<T>?
    var indices: (a: Int, b: Int)
    var parent: Node<T>?

    init(_ diff: Diff<T>? = nil, at: (Int, Int), parent: Node<T>? = nil) {
        self.diff = diff
        self.indices = (a: at.0, b: at.1)
        self.parent = parent
    }

    var list: [Node<T>] {
        var parent: Node<T>? = self
        var list: [Node<T>] = []
        while let nextParent = parent {
            list.insert(nextParent, at: 0)
            parent = nextParent.parent
        }
        return list
    }

    var seq: [Diff<T>] {
        var parent: Node<T>? = self
        var list: [Diff<T>] = []
        while let nextParent = parent, let diff = nextParent.diff {
            list.insert(diff, at: 0)
            parent = nextParent.parent
        }
        return list
    }

    var score: Float { return Diff.seq(seq).score }

    var desc: String {
        var x = 0
        let length = indices.a + 1
        var output = String(repeating: ".", count: length) + "...\n."
        var prefix = ""
        for node in list {
            guard let simpleDiff = node.diff?.simple else { continue }

            output += prefix
            switch simpleDiff {
            case .delete:
                output += ">"
                x += 1
                prefix = ""
            case .insert:
                output += "v"
                output += String(repeating: " ", count: length - x)
                prefix = ".\n." + String(repeating: " ", count: x)
            case .same:
                output += "\\"
                output += String(repeating: " ", count: length - x)
                x += 1
                prefix = ".\n." + String(repeating: " ", count: x)
            }
        }
        output += ".\n" + String(repeating: ".", count: length) + "..."
        let header = "(score: \(score))"
        return header + "\n" + output
    }

    func any(parentIs cmp: SimpleDiff) -> Bool {
        var parent = self.parent
        while let nextParent = parent {
            if nextParent.diff?.equals(.same) == true { return false }
            if nextParent.diff?.equals(cmp) == true { return true }
            parent = nextParent.parent
        }
        return false
    }
}
