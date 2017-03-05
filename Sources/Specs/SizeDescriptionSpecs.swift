////
///  SizeDescriptionSpecs.swift
//


struct SizeDescriptionSpecs: SpecRunner {
    let name = "SizeDescriptionSpecs"
    let parentSize = Size(width: 20, height: 40)
    let sizeZeroDescription = SizeDescription(multiplier: FloatSize(width: 0, height: 0), offset: Size(width: 0, height: 0))
    let sizeTenDescription = SizeDescription(multiplier: FloatSize(width: 0, height: 0), offset: Size(width: 10, height: 10))

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        testSize(expect, SizeDescription.size(width: 10, height: 10), becomes: Size(width: 10, height: 10), "SizeDescription.size")

        testSize(expect, SizeDescription.width(10), becomes: Size(width: 10, height: 1), "SizeDescription.width")
        testSize(expect, SizeDescription.width(percent: 50), becomes: Size(width: 10, height: 1), "SizeDescription.width")
        testSize(expect, SizeDescription.width(times: 0.25), becomes: Size(width: 5, height: 1), "SizeDescription.width")
        testSize(expect, SizeDescription.width(plus: 5), becomes: Size(width: 25, height: 1), "SizeDescription.width")
        testSize(expect, SizeDescription.width(minus: 5), becomes: Size(width: 15, height: 1), "SizeDescription.width")
        testSize(expect, SizeDescription.width(times: 0.25, plus: 1), becomes: Size(width: 6, height: 1), "SizeDescription.width")

        testSize(expect, sizeZeroDescription.width(10), becomes: Size(width: 10, height: 0), "sizeZeroDescription.width")
        testSize(expect, sizeZeroDescription.width(percent: 50), becomes: Size(width: 10, height: 0), "sizeZeroDescription.width")
        testSize(expect, sizeZeroDescription.width(times: 0.25), becomes: Size(width: 5, height: 0), "sizeZeroDescription.width")
        testSize(expect, sizeZeroDescription.width(plus: 5), becomes: Size(width: 25, height: 0), "sizeZeroDescription.width")
        testSize(expect, sizeZeroDescription.width(minus: 5), becomes: Size(width: 15, height: 0), "sizeZeroDescription.width")
        testSize(expect, sizeZeroDescription.width(times: 0.25, plus: 1), becomes: Size(width: 6, height: 0), "sizeZeroDescription.width")

        testSize(expect, SizeDescription.height(10), becomes: Size(width: 1, height: 10), "SizeDescription.height")
        testSize(expect, SizeDescription.height(percent: 50), becomes: Size(width: 1, height: 20), "SizeDescription.height")
        testSize(expect, SizeDescription.height(times: 0.25), becomes: Size(width: 1, height: 10), "SizeDescription.height")
        testSize(expect, SizeDescription.height(plus: 5), becomes: Size(width: 1, height: 45), "SizeDescription.height")
        testSize(expect, SizeDescription.height(minus: 5), becomes: Size(width: 1, height: 35), "SizeDescription.height")
        testSize(expect, SizeDescription.height(times: 0.25, plus: 1), becomes: Size(width: 1, height: 11), "SizeDescription.height")

        testSize(expect, sizeZeroDescription.height(10), becomes: Size(width: 0, height: 10), "sizeZeroDescription.height")
        testSize(expect, sizeZeroDescription.height(percent: 50), becomes: Size(width: 0, height: 20), "sizeZeroDescription.height")
        testSize(expect, sizeZeroDescription.height(times: 0.25), becomes: Size(width: 0, height: 10), "sizeZeroDescription.height")
        testSize(expect, sizeZeroDescription.height(plus: 5), becomes: Size(width: 0, height: 45), "sizeZeroDescription.height")
        testSize(expect, sizeZeroDescription.height(minus: 5), becomes: Size(width: 0, height: 35), "sizeZeroDescription.height")
        testSize(expect, sizeZeroDescription.height(times: 0.25, plus: 1), becomes: Size(width: 0, height: 11), "sizeZeroDescription.height")

        testSize(expect, SizeDescription.minus(1), becomes: Size(width: 19, height: 39), "SizeDescription.minus")
        testSize(expect, SizeDescription.minus(width: 1, height: 2), becomes: Size(width: 19, height: 38), "SizeDescription.minus")
        testSize(expect, sizeZeroDescription.minus(1), becomes: Size(width: 19, height: 39), "sizeZeroDescription.minus")
        testSize(expect, sizeZeroDescription.minus(width: 1, height: 2), becomes: Size(width: 19, height: 38), "sizeZeroDescription.minus")

        testSize(expect, SizeDescription.plus(1), becomes: Size(width: 21, height: 41), "SizeDescription.plus")
        testSize(expect, SizeDescription.plus(width: 1, height: 2), becomes: Size(width: 21, height: 42), "SizeDescription.plus")
        testSize(expect, sizeZeroDescription.plus(1), becomes: Size(width: 21, height: 41), "sizeZeroDescription.plus")
        testSize(expect, sizeZeroDescription.plus(width: 1, height: 2), becomes: Size(width: 21, height: 42), "sizeZeroDescription.plus")

        testSize(expect, SizeDescription.fullWidth(plus: 1), becomes: Size(width: 21, height: 1), "SizeDescription.fullWidth")
        testSize(expect, SizeDescription.fullWidth(minus: 1), becomes: Size(width: 19, height: 1), "SizeDescription.fullWidth")
        testSize(expect, sizeZeroDescription.fullWidth(minus: 5), becomes: Size(width: 15, height: 0), "sizeZeroDescription.fullWidth")

        testSize(expect, SizeDescription.fullHeight(plus: 1), becomes: Size(width: 1, height: 41), "SizeDescription.fullHeight")
        testSize(expect, SizeDescription.fullHeight(minus: 1), becomes: Size(width: 1, height: 39), "SizeDescription.fullHeight")
        testSize(expect, sizeZeroDescription.fullHeight(minus: 5), becomes: Size(width: 0, height: 35), "sizeZeroDescription.fullHeight")

        done()
    }

    func testSize(_ expect: (String) -> Expectations, _ size: SizeDescription,
        becomes expectedSize: Size, _ desc: String
    ) {
        let calcSize = size.calcSize(in: parentSize)
        expect("width \(size.multiplier.width)*\(parentSize.width) + \(size.offset.width)").assertEqual(calcSize.width, expectedSize.width, desc)
        expect("height \(size.multiplier.height)*\(parentSize.height) + \(size.offset.height)").assertEqual(calcSize.height, expectedSize.height, desc)
    }
}
