////
///  Debug.swift
//

private var debugSilenced = false
var debugEntries: [String] = []

// prints to stdout when application exits
public func debug(_ entry: Any) {
    guard !debugSilenced else { return }
    debugEntries.append("\(entry)")
}
public func debugSilenced(_ val: Bool) {
    debugSilenced = val
}
