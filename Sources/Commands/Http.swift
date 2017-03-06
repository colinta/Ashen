////
///  Http.swift
//

import Foundation


enum HttpError: Error {
    case system(Error)
    case unknown
}

class Command<T> {
    func start(_ done: @escaping (T) -> Void) {
    }

    func map<T, U>(_ mapper: @escaping (T) -> U) -> Command<U> {
        return Command<U>()
    }
}

class Http<T>: Command<T> {
    typealias HttpResult = Result<(Data, URLResponse), HttpError>
    typealias OnReceivedHandler = (HttpResult) -> T?

    let url: URL
    var config: URLSessionConfiguration
    var onReceived: OnReceivedHandler
    init(url: URL, timeout: TimeInterval? = nil, onReceived: @escaping OnReceivedHandler) {
        debug("create")
        self.url = url
        let config = URLSessionConfiguration.default
        if let timeout = timeout {
            config.timeoutIntervalForResource = timeout
        }
        self.config = config
        self.onReceived = onReceived
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> Command<U> {
        let myReceived = self.onReceived
        let onReceived: (HttpResult) -> U? = { result in
            return myReceived(result).map { (msg: T) -> U in return mapper(msg) }
        }
        let command = Http<U>(url: url, onReceived: onReceived)
        command.config = config
        return command
    }

    override func start(_ done: @escaping (T) -> Void) {
        let request = URLRequest(url: url)
        let task = URLSession(configuration: config).dataTask(with: request, completionHandler: { data, response, error in
            debug("receive")
            let result: HttpResult
            if let data = data, let response = response {
                result = .ok((data, response))
            }
            else if let error = error {
                result = .fail(.system(error))
            }
            else {
                result = .fail(.unknown)
            }

            if let message = self.onReceived(result) {
                done(message)
            }
        })
        debug("send")
        task.resume()
    }
}

/*
let urlStr = "http://colinta.com"
let url = URL(string: urlStr)
let request = URLRequest(url: url!)
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config)
let task = session.dataTask(with: request, completionHandler: { data, response, error in
        print("data \(data)")
        print("response \(response)")
        print("error \(error)")
    })
task.resume()
*/
