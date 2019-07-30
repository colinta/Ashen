////
///  BoxSpecs.swift
//

@testable import Ashen

struct BoxSpecs: Spec {
    var name: String { return "BoxSpecs" }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        let border = Box.Border(
            dot: ".", topCap: "T", bottomCap: "U", leftCap: "L", rightCap: "R",
            tlCorner: "!", trCorner: "@", blCorner: "#", brCorner: "$",
            tbSide: "=", topSide: "_", bottomSide: "-",
            lrSide: "|", leftSide: ">", rightSide: "<"
            )
        let borderDefaults = Box.Border(
            tlCorner: "!", trCorner: "@", blCorner: "#", brCorner: "$",
            tbSide: "-", lrSide: "|"
            )
        expect("outputs nothing")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 0, height: 0), border: border, background: "x"), "", "when width,height == 0")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 1, height: 0), border: border, background: "x"), "", "when height == 0")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 0, height: 1), border: border, background: "x"), "", "when width == 0")
        expect("outputs dot")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 1, height: 1), border: border, background: "x"), ".")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 1, height: 1), border: borderDefaults, background: "x"), "!", "defaults")
        expect("outputs top/bottom caps")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 1, height: 3), border: border, background: "x"), "T\n|\nU")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 1, height: 3), border: borderDefaults, background: "x"), "!\n|\n#", "defaults")
        expect("outputs left/right caps")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 3, height: 1), border: border, background: "x"), "L=R")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 3, height: 1), border: borderDefaults, background: "x"), "!-@", "defaults")
        expect("outputs corners")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 2, height: 2), border: border, background: "x"), "!@\n#$")
        expect("outputs box with background")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 3, height: 3), border: border, background: "x"), "!_@\n>x<\n#-$")
        expect("background only")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 3, height: 3), background: "x"), "xxx\nxxx\nxxx")

        expect("outputs components, no border")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 5, height: 5), background: "x", components: [
                LabelView(at: .middleCenter(), text: "hi!")
                ]), "xxxxx\nxxxxx\nxhi!x\nxxxxx\nxxxxx")
        expect("outputs components, with border")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 5, height: 5), border: .single, background: "_", components: [
                LabelView(at: .middleCenter(), text: "hi!")
                ]), "┌───┐\n│___│\n│hi!│\n│___│\n└───┘")
        expect("outputs scrolled components, with border")
            .assertRenders(Box(at: .topLeft(), size: Size(width: 5, height: 5), border: .doubleSides, background: "_", components: [
                    LabelView(at: .topLeft(x: 0, y: 0), text: "abcdefghij"),
                    LabelView(at: .topLeft(x: 0, y: 1), text: "ABCDEFGHIJ"),
                    LabelView(at: .topLeft(x: 0, y: 2), text: "1234567890"),
                    LabelView(at: .topLeft(x: 0, y: 3), text: "klmnopqrst"),
                    LabelView(at: .topLeft(x: 0, y: 4), text: "KLMNOPQRST"),
                    LabelView(at: .topLeft(x: 0, y: 5), text: "!@#$%^&*()"),
                ], scrollOffset: Point(x: 1, y: 1)), "╓───╖\n║BCD║\n║234║\n║lmn║\n╙───╜")
        done()
    }
}
