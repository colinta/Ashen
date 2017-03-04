////
///  SpecRunner.swift
//


protocol SpecRunner {
    var name: String { get }
    func run(expect: (String) -> Expectations, done: @escaping () -> Void)
}
