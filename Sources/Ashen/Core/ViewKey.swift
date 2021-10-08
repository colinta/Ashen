////
///  ViewKey.swift
//

public enum ViewKey: Equatable {
    case none
    // a global id, useful for views that move through the view tree
    case id(String)
    // a named subview, useful for views that reorder but stay in the same branch of the tree
    case key(String)
    // the default name created by the parent view
    case name(String)
    // the default name created by a parent view iterating child views
    case index(Int)
    case path(String)

    var bufferKey: String {
        switch (self) {
        case .none:
            return ""
        case let .id(id):
            return "#\(id)"
        case let .key(key):
            return "{\(key)}"
        case let .name(name):
            return ".\(name)"
        case let .index(index):
            return "[\(index)]"
        case let .path(path):
            return path
        }
    }

    public static func == (lhs: ViewKey, rhs: ViewKey) -> Bool {
        lhs.bufferKey == rhs.bufferKey
    }

    func append(key nextKey: ViewKey) -> ViewKey {
        if case .none = self {
            return nextKey
        }

        switch (nextKey) {
        case .none:
            return self
        case .id:
            return nextKey
        case .key, .name, .index, .path:
            return .path(bufferKey + nextKey.bufferKey)
        }
    }
}
