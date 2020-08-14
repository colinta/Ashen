////
///  Timeout.swift
//

import Foundation

public func Timeout<Msg>(
    _ delay: TimeInterval, _ onTimeout: @escaping @autoclosure SimpleEvent<Msg>
)
    -> Command<Msg>
{
    Command { send in
        Thread.sleep(forTimeInterval: delay)
        send(onTimeout())
    }
}
