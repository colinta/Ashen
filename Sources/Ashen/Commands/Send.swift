////
///  Send.swift
//

public func Send<Msg>(_ msg: @escaping @autoclosure SimpleEvent<Msg>) -> Command<Msg> {
    Command { send in
        send(msg())
    }
}
