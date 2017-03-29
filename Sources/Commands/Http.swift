////
///  Http.swift
//

import Foundation


enum HttpError: Error {
    case system(Error)
    case noDataAtUrl(URL)
    case unknown
}

enum HttpOptions {
    // mixing concerns here, but it's easy & handy to have these as "options"
    // rather than additional arguments.  background & ephemeral control what
    // type of URLSessionConfiguration object is created.
    case background(String)
    case ephemeral

    case timeout(TimeInterval)
    case requestTimeout(TimeInterval)
    case resourceTimeout(TimeInterval)
    case headers([String: String])
    case header(String, String)
    case networkService(NSURLRequest.NetworkServiceType)  // default, voip, video, background, voice
    case allowsCellular(Bool)
    case sharedContainer(String)
    /*
     * TODO:
     * httpCookieAcceptPolicy(HTTPCookie.AcceptPolicy)
     * httpCookieStorage(HTTPCookieStorage)
     * httpShouldSetCookies(Bool)
     * tlsMaximumSupportedProtocol(SSLProtocol)
     * tlsMinimumSupportedProtocol(SSLProtocol)
     * urlCredentialStorage(URLCredentialStorage)
     * urlCache(URLCache)
     * requestCachePolicy(NSURLRequest.CachePolicy)
     * sessionSendsLaunchEvents(Bool)
     * isDiscretionary(Bool)
     * httpMaximumConnectionsPerHost(Int)
     * httpShouldUsePipelining(Bool)
     * connectionProxyDictionary([AnyHashable : Any])
     * shouldUseExtendedBackgroundIdleMode(Bool)
     */

    func apply(toConfig config: URLSessionConfiguration) {
        var headers: [String: String] = [:]

        switch self {
        case let .timeout(value):
            config.timeoutIntervalForRequest = value
            config.timeoutIntervalForResource = value
        case let .requestTimeout(value):
            config.timeoutIntervalForRequest = value
        case let .resourceTimeout(value):
            config.timeoutIntervalForResource = value
        case let .headers(newHeaders):
            for (name, value) in newHeaders {
                headers[name] = value
            }
        case let .header(name, value):
            headers[name] = value
        case let .networkService(value):
            config.networkServiceType = value
        case let .allowsCellular(value):
            config.allowsCellularAccess = value
        case let .sharedContainer(value):
            config.sharedContainerIdentifier = value

        default:
            break
        }

        if headers.count > 0 {
            config.httpAdditionalHeaders = headers
        }
    }

    func apply(toSession session: URLSessionProtocol) {
    }
}


protocol URLSessionProtocol: class {
    func ashen_dataTask(with: URLRequest) -> URLSessionTaskProtocol
    func ashen_downloadTask(with: URLRequest) -> URLSessionTaskProtocol
    func ashen_cancel()
}
extension URLSession: URLSessionProtocol {
    func ashen_dataTask(with request: URLRequest) -> URLSessionTaskProtocol {
        return dataTask(with: request)
    }

    func ashen_downloadTask(with request: URLRequest) -> URLSessionTaskProtocol {
        return downloadTask(with: request)
    }

    func ashen_cancel() {
        invalidateAndCancel()
    }
}


protocol URLSessionTaskProtocol: class {
    func ashen_start()
}
extension URLSessionTask: URLSessionTaskProtocol {
    func ashen_start() {
        resume()
    }
}


enum URLSessionHandler {
    case system
    case mock((URLSessionConfiguration) -> URLSessionProtocol)

    func create(config: URLSessionConfiguration, delegate: URLSessionDelegate) -> URLSessionProtocol {
        switch self {
        case .system:
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        case let .mock(mock):
            return mock(config)
        }
    }
}


class Http: Command {
    class Delegate: NSObject {
        var lastSentProgress = Date()
        var onReceived: ((Data?, Error?) -> Void)?
        var onProgress: ((Float) -> Void)?
    }

    typealias HttpResult = Result<Data>
    typealias OnProgressHandler = (Float) -> AnyMessage?
    typealias OnReceivedHandler = (HttpResult) -> AnyMessage?

    let urlSessionDelegate = Delegate()
    let request: URLRequest
    let session: URLSessionProtocol
    var onProgress: OnProgressHandler?
    var onReceived: OnReceivedHandler

    static func get(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }
    static func post(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }
    static func put(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }
    static func patch(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }
    static func delete(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }
    static func head(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }
    static func options(url: URL, options: [HttpOptions] = [], onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) -> Http {
        var request = URLRequest(url: url)
        request.httpMethod = "OPTIONS"
        return Http(request: request, options: options, onProgress: onProgress, onReceived: onReceived)
    }

    init(request: URLRequest, options: [HttpOptions] = [], urlSessionHandler: URLSessionHandler = .system, onProgress: OnProgressHandler? = nil, onReceived: @escaping OnReceivedHandler) {
        self.request = request

        var isEphemeral = false
        var backgroundIdentifier: String?
        for option in options {
            if case let .background(identifier) = option {
                backgroundIdentifier = identifier
                break
            }
            if case .ephemeral = option {
                isEphemeral = false
                break
            }
        }

        let config: URLSessionConfiguration
        if let backgroundIdentifier = backgroundIdentifier {
            config = URLSessionConfiguration.background(withIdentifier: backgroundIdentifier)
        }
        else if isEphemeral {
            config = URLSessionConfiguration.ephemeral
        }
        else {
            config = URLSessionConfiguration.default
        }

        for option in options {
            option.apply(toConfig: config)
        }
        self.onReceived = onReceived
        self.onProgress = onProgress

        self.session = urlSessionHandler.create(config: config, delegate: urlSessionDelegate)
        for option in options {
            option.apply(toSession: session)
        }
    }

    func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let command = self
        let myReceived = self.onReceived
        let onReceived: (HttpResult) -> U? = { result in
            return myReceived(result).map { mapper($0 as! T) }
        }
        command.onReceived = onReceived

        if let myProgress = self.onProgress {
            let onProgress: (Float) -> U? = { result in
                return myProgress(result).map { mapper($0 as! T) }
            }
            command.onProgress = onProgress
        }

        return command
    }

    func cancel() {
        session.ashen_cancel()
    }

    func start(_ done: @escaping (AnyMessage) -> Void) {
        urlSessionDelegate.onReceived = { data, error in
            let result: HttpResult
            if let data = data {
                result = .ok(data)
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

        if let onProgress = onProgress {
            urlSessionDelegate.onProgress = { amt in
                onProgress(amt).map { done($0) }
            }
            startDownloadTask(request, done)
        }
        else {
            startDataTask(request, done)
        }
    }

    private func startDataTask(_ request: URLRequest, _ done: @escaping (AnyMessage) -> Void) {
        let task = session.ashen_dataTask(with: request)
        task.ashen_start()
    }

    private func startDownloadTask(_ request: URLRequest, _ done: @escaping (AnyMessage) -> Void) {
        let task = session.ashen_downloadTask(with: request)
        task.ashen_start()
    }
}

extension Http.Delegate: URLSessionDelegate {
}
extension Http.Delegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let onReceived = onReceived, let error = error else { return }
        onReceived(nil, error)
    }
}
extension Http.Delegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let onReceived = onReceived else { return }
        onReceived(data, nil)
    }
}
extension Http.Delegate: URLSessionDownloadDelegate {
    @available(OSX 10.9, *)
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo url: URL) {
        guard let onReceived = onReceived else { return }
        if let data = try? Data(contentsOf: url, options: []) {
            onReceived(data, nil)
        }
        else {
            onReceived(nil, HttpError.noDataAtUrl(url))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten totalWritten: Int64, totalBytesExpectedToWrite expected: Int64) {
        guard expected > 0, Date().timeIntervalSince(lastSentProgress) > 0.1 else { return }
        onProgress?(Float(totalWritten) / Float(expected))
        lastSentProgress = Date()
    }
}
