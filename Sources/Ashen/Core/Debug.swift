////
///  Debug.swift
//

private var _debugSilenced = false
var debugEntries: [String] = []

// prints to stdout when application exits
public func debug(_ entry: Any) {
    guard !_debugSilenced else { return }
    debugEntries.append("\(entry)")
}
public func debugSilenced() -> Bool { _debugSilenced }
public func debugSilenced(_ val: Bool) {
    _debugSilenced = val
}
