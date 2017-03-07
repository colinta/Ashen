////
///  Http.swift
//

import Foundation


enum HttpError: Error {
    case system(Error)
    case unknown
}

enum HttpOptions {
    case timeout(TimeInterval)
    case headers([String: String])
    case header(String, String)

    func apply(toConfig config: URLSessionConfiguration) {
        var headers: [String: String] = [:]
        switch self {
        case let .timeout(timeout):
            config.timeoutIntervalForResource = timeout
        case let .headers(newHeaders):
            for (name, value) in newHeaders {
                headers[name] = value
            }
        case let .header(name, value):
            headers[name] = value
        }

        if headers.count > 0 {
            config.httpAdditionalHeaders = headers
        }
    }
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}

protocol URLSessionTaskProtocol {
    func ashen_start()
}

typealias URLSessionCompletionHandler = (Data?, URLResponse?, Error?) -> Void
protocol URLSessionProtocol {
    func ashen_dataTask(with: URLRequest, completionHandler: @escaping URLSessionCompletionHandler) -> URLSessionTaskProtocol
    func ashen_cancel()
}

extension URLSession: URLSessionProtocol {
    func ashen_dataTask(with request: URLRequest, completionHandler: @escaping URLSessionCompletionHandler) -> URLSessionTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler)
    }

    func ashen_cancel() {
        invalidateAndCancel()
    }
}

extension URLSessionTask: URLSessionTaskProtocol {
    func ashen_start() {
        resume()
    }
}

enum URLSessionHandler {
    case system
    case mock(URLSessionProtocol)

    func create(config: URLSessionConfiguration) -> URLSessionProtocol {
        switch self {
        case .system:
            return URLSession(configuration: config)
        case let .mock(mock):
            return mock
        }
    }
}

class Http: Command {
    typealias HttpResult = Result<(Data, URLResponse)>
    typealias OnReceivedHandler = (HttpResult) -> AnyMessage?

    let url: URL
    let method: HttpMethod
    let session: URLSessionProtocol
    var onReceived: OnReceivedHandler

    static func get(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .get, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }
    static func post(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .post, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }
    static func put(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .put, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }
    static func patch(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .patch, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }
    static func delete(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .delete, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }
    static func head(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .head, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }
    static func options(url: URL, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) -> Http {
        return Http(url: url, method: .options, options: options, urlSessionHandler: urlSessionHandler, onReceived: onReceived)
    }

    init(url: URL, method: HttpMethod = .get, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onReceived: @escaping OnReceivedHandler) {
        self.url = url
        self.method = method
        let config = URLSessionConfiguration.default
        for option in options {
            option.apply(toConfig: config)
        }
        self.onReceived = onReceived
        self.session = urlSessionHandler.create(config: config)
    }

    func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let command = self
        let myReceived = self.onReceived
        let onReceived: (HttpResult) -> U? = { result in
            return myReceived(result).map { mapper($0 as! T) }
        }
        command.onReceived = onReceived
        return command
    }

    func cancel() {
        session.ashen_cancel()
    }

    func start(_ done: @escaping (AnyMessage) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        let task = session.ashen_dataTask(with: request) { data, response, error in
            let result: HttpResult
            if let data = data, let response = response {
                result = .ok((data, response))
            }
            else if let error = error {
                result = .fail(HttpError.system(error))
            }
            else {
                result = .fail(HttpError.unknown)
            }

            if let message = self.onReceived(result) {
                done(message)
            }
        }
        task.ashen_start()
    }
}
