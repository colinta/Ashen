////
///  String.swift
//

extension String {
    public var lines: [Substring] {
        split(separator: "\n", omittingEmptySubsequences: false)
    }

    public var firstLine: String {
        String(split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)[0])
    }

    public var countLines: Int {
        lines.count
    }

    public var maxWidth: Int {
        lines.reduce(0) { memo, line in
            max(memo, line.reduce(0) { len, c in
                len + Buffer.displayWidth(of: c)
            })
        }
    }
}
