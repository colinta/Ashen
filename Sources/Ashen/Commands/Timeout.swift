////
///  Timeout.swift
//

import Foundation

public func Timeout<Msg>(_ delay: TimeInterval, _ onTimeout: @escaping @autoclosure () -> Msg) -> Command<Msg> {
    Command { done in
        Thread.sleep(forTimeInterval: delay)
        done(onTimeout())
    }
}
