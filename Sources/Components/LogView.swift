////
///  LogView.swift
//

class LogView: ComponentLayout {
    let size: Size

    init(y startY: Int, entries: [String], screenSize: Size) {
        let maxEntries = max(0, screenSize.height - startY)
        size = Size(width: screenSize.width, height: screenSize.height - startY)
        let trimmedEntries: [String]
        if maxEntries == 0 {
            trimmedEntries = []
        }
        else if entries.count <= maxEntries {
            trimmedEntries = entries
        }
        else {
            trimmedEntries = entries.reversed()[0..<maxEntries].reversed()
        }

        super.init()
        location = .tl(y: startY)
        var y = 0
        components = trimmedEntries.map { entry in
            let component = LabelView(.tl(x: 1, y: y), text: entry)
            y += 1
            return component
        }
    }

    override func desiredSize() -> DesiredSize {
        return DesiredSize(size)
    }
}
