////
///  Attributed+Codable.swift
//

import Foundation

public struct AttributedCoder: Codable {
    let spans: [AttributedSpan]

    public init(_ attributed: Attributed) {
        let (spans, _) = attributed.attributedCharacters.reduce(([AttributedSpan](), [Attr]())) {
            spans_attrs, ac in
            var (spans, attrs) = spans_attrs
            if ac.attributes == attrs, let last = spans.popLast() {
                return (
                    spans + [
                        AttributedSpan(string: last.string + "\(ac.character)", attrs: last.attrs)
                    ], attrs
                )
            } else {
                return (
                    spans + [
                        AttributedSpan(
                            string: "\(ac.character)",
                            attrs: ac.attributes.map { AttrCoder(attr: $0) })
                    ], ac.attributes
                )
            }
        }
        self.spans = spans
    }

    public func toAttributed() -> AttributedString {
        self.spans.reduce(AttributedString()) { memo, span in
            memo + AttributedString(span.string, attributes: span.attrs.compactMap { $0.toAttr() })
        }
    }

    struct AttributedSpan: Codable {
        let string: String
        let attrs: [AttrCoder]
    }

    struct AttrCoder: Codable {
        enum AttrType: String, Codable {
            case none
            case underline
            case reverse
            case bold
            case foreground
            case background
        }

        enum NamedColor: String, Codable {
            case none
            case black
            case red
            case green
            case yellow
            case blue
            case magenta
            case cyan
            case white
        }

        let attr: AttrType
        let namedColor: NamedColor?
        let intColor: AttrSize?

        enum CodingKeys: String, CodingKey {
            case attr
            case name
            case int
        }

        init(attr: Attr) {
            switch attr {
            case .none:
                self.attr = .none
                self.namedColor = nil
                self.intColor = nil
            case .underline:
                self.attr = .underline
                self.namedColor = nil
                self.intColor = nil
            case .reverse:
                self.attr = .reverse
                self.namedColor = nil
                self.intColor = nil
            case .bold:
                self.attr = .bold
                self.namedColor = nil
                self.intColor = nil
            case let .foreground(color):
                let (raw, int) = AttrCoder.encode(color: color)
                self.attr = .foreground
                self.namedColor = raw
                self.intColor = int
            case let .background(color):
                self.attr = .background
                let (raw, int) = AttrCoder.encode(color: color)
                self.namedColor = raw
                self.intColor = int
            }
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.attr = try values.decode(AttrType.self, forKey: .attr)
            if let namedColor = try? values.decode(NamedColor.self, forKey: .name) {
                self.namedColor = namedColor
                self.intColor = nil
            } else if let intColor = try? values.decode(AttrSize.self, forKey: .int) {
                self.namedColor = nil
                self.intColor = intColor
            } else {
                self.namedColor = nil
                self.intColor = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(attr, forKey: .attr)
            if let namedColor = namedColor {
                try container.encode(namedColor, forKey: .name)
            }
            if let intColor = intColor {
                try container.encode(intColor, forKey: .int)
            }
        }

        private static func encode(color: Ashen.Color) -> (NamedColor?, AttrSize?) {
            switch color {
            case .none:
                return (NamedColor.none, nil)
            case .black:
                return (.black, nil)
            case .red:
                return (.red, nil)
            case .green:
                return (.green, nil)
            case .yellow:
                return (.yellow, nil)
            case .blue:
                return (.blue, nil)
            case .magenta:
                return (.magenta, nil)
            case .cyan:
                return (.cyan, nil)
            case .white:
                return (.white, nil)
            case let .any(intColor):
                return (nil, intColor)
            }
        }

        private func decode(_ namedColor: NamedColor?, _ intColor: AttrSize?) -> Color? {
            if let namedColor = namedColor {
                switch namedColor {
                case .none:
                    return Color.none
                case .black:
                    return .black
                case .red:
                    return .red
                case .green:
                    return .green
                case .yellow:
                    return .yellow
                case .blue:
                    return .blue
                case .magenta:
                    return .magenta
                case .cyan:
                    return .cyan
                case .white:
                    return .white
                }
            } else if let intColor = intColor {
                return .any(intColor)
            }
            return nil
        }

        func toAttr() -> Attr? {
            switch attr {
            case .none:
                return Attr.none
            case .underline:
                return .underline
            case .reverse:
                return .reverse
            case .bold:
                return .bold
            case .foreground:
                guard let color = decode(namedColor, intColor) else { return nil }
                return .foreground(color)
            case .background:
                guard let color = decode(namedColor, intColor) else { return nil }
                return .background(color)
            }
        }
    }
}
