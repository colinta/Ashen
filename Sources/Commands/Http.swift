////
///  Http.swift
//

import Foundation


enum HttpError: Error {
    case system(Error)
    case unknown
}

class Command {
    func start(_ done: @escaping (AnyMessage) -> Void) {
    }

    func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        return self
    }
}

class Http: Command {
    typealias HttpResult = Result<(Data, URLResponse), HttpError>
    typealias OnReceivedHandler = (HttpResult) -> AnyMessage?

    let url: URL
    var config: URLSessionConfiguration
    var onReceived: OnReceivedHandler
    init(url: URL, timeout: TimeInterval? = nil, onReceived: @escaping OnReceivedHandler) {
        self.url = url
        let config = URLSessionConfiguration.default
        if let timeout = timeout {
            config.timeoutIntervalForResource = timeout
        }
        self.config = config
        self.onReceived = onReceived
    }

    override func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let command = self
        let myReceived = self.onReceived
        let onReceived: (HttpResult) -> U? = { result in
            return myReceived(result).map { mapper($0 as! T) }
        }
        command.onReceived = onReceived
        command.config = config
        return command
    }

    override func start(_ done: @escaping (AnyMessage) -> Void) {
        let request = URLRequest(url: url)
        let task = URLSession(configuration: config).dataTask(with: request, completionHandler: { data, response, error in
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
