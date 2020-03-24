////
///  Http.swift
//

import Foundation


public enum HttpError: Error {
    case system(Int, Error)
    case noDataAtUrl(Int, URL)
    case unknown(Int)
}

public enum HttpOption {
    // mixing concerns here, but it's easy & handy to have these as "options"
    // rather than additional arguments.  background & ephemeral control what
    // type of URLSessionConfiguration object is created.
    case background(String)
    case ephemeral

    // URLRequest
    case method(Http.Method)
    case body(Http.Body)
    case headers(Http.Headers)
    case header(String, String)
    case setHeader(String, String)
    case removeHeader(String)

    // session configuration
    case timeout(TimeInterval)
    case requestTimeout(TimeInterval)
    case resourceTimeout(TimeInterval)
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

    public func apply(toConfig config: URLSessionConfiguration) {
        switch self {
        case let .timeout(value):
            config.timeoutIntervalForRequest = value
            config.timeoutIntervalForResource = value
        case let .requestTimeout(value):
            config.timeoutIntervalForRequest = value
        case let .resourceTimeout(value):
            config.timeoutIntervalForResource = value
        case let .networkService(value):
            config.networkServiceType = value
        case let .allowsCellular(value):
            config.allowsCellularAccess = value
        case let .sharedContainer(value):
            config.sharedContainerIdentifier = value

        default:
            break
        }
    }

    public func apply(toRequest request: inout URLRequest) {
        switch self {
        case let .method(method):
            request.httpMethod = method.rawValue
        case let .header(key, value):
            request.addValue(value, forHTTPHeaderField: key)
        case let .setHeader(key, value):
            request.setValue(value, forHTTPHeaderField: key)
        case let .removeHeader(key):
            request.setValue(nil, forHTTPHeaderField: key)
        case let .headers(headers):
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.name)
            }
        default:
            break
        }
    }

    public func apply(toSession session: URLSessionProtocol) {
    }
}

func responseToHeaders(_ response: URLResponse?) -> Http.Headers {
    guard let response = response as? HTTPURLResponse else { return [] }
    return response.allHeaderFields.compactMap { name, value -> Http.Header? in
        guard let name = name as? String, let value = value as? String else { return nil }
        return Http.Header(name: name, value: value)
    }
}

public protocol URLSessionProtocol: class {
    func ashenDataTask(with: URLRequest, completionHandler: Http.Delegate.OnReceivedHandler?)
        -> URLSessionTaskProtocol
    func ashenDownloadTask(with: URLRequest, completionHandler: Http.Delegate.OnReceivedHandler?)
        -> URLSessionTaskProtocol
    func ashenCancel()
}
extension URLSession: URLSessionProtocol {
    public func ashenDataTask(
        with request: URLRequest,
        completionHandler: Http.Delegate.OnReceivedHandler?
    ) -> URLSessionTaskProtocol {
        dataTask(with: request) { data, response, error in
            completionHandler?(
                (response as? HTTPURLResponse)?.statusCode ?? 0,
                responseToHeaders(response),
                data,
                error
            )
        }
    }

    public func ashenDownloadTask(
        with request: URLRequest,
        completionHandler: Http.Delegate.OnReceivedHandler?
    ) -> URLSessionTaskProtocol {
        downloadTask(with: request) { url, response, error in
            if let url = url,
                let data = try? Data(contentsOf: url, options: [])
            {
                completionHandler?(
                    (response as? HTTPURLResponse)?.statusCode ?? 0,
                    responseToHeaders(response),
                    data,
                    error
                )
            }
            else {
                completionHandler?(
                    (response as? HTTPURLResponse)?.statusCode ?? 0,
                    responseToHeaders(response),
                    nil,
                    error
                )
            }
        }
    }

    public func ashenCancel() {
        invalidateAndCancel()
    }
}


public protocol URLSessionTaskProtocol: class {
    func ashenStart()
}
extension URLSessionTask: URLSessionTaskProtocol {
    public func ashenStart() {
        resume()
    }
}


public enum URLSessionHandler {
    case system
    case mock((URLSessionConfiguration) -> URLSessionProtocol)

    func create(config: URLSessionConfiguration, delegate: URLSessionDelegate) -> URLSessionProtocol
    {
        switch self {
        case .system:
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        case let .mock(mock):
            return mock(config)
        }
    }
}


public class Http: Command {
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }

    public enum Body {
        case string(String)
        case data(Data)

        var toData: Data? {
            switch self {
            case let .string(string):
                return string.data(using: .utf8)
            case let .data(data):
                return data
            }
        }
    }

    public class Delegate: NSObject {
        public typealias OnProgressHandler = ((Float) -> Void)
        public typealias OnReceivedHandler = ((Int, Http.Headers, Data?, Error?) -> Void)

        var lastSentProgress = Date()
        var onReceived: OnReceivedHandler?
        var onProgress: OnProgressHandler?
    }

    public struct Header {
        public let name: String
        public let value: String

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }

        public enum Name: String {
            case contentType = "content-type"
        }

        public func `is`(_ other: Name) -> Bool {
            name.lowercased() == other.rawValue
        }
    }
    public typealias Headers = [Header]
    public typealias Options = [HttpOption]
    public typealias HttpResult = Result<(Int, Headers, Data)>
    public typealias OnProgressHandler = (Float) -> AnyMessage?
    public typealias OnReceivedHandler = (HttpResult) -> AnyMessage?

    let urlSessionDelegate = Delegate()
    let request: URLRequest
    let session: URLSessionProtocol
    var onProgress: OnProgressHandler?
    var onReceived: OnReceivedHandler

    public static func get(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.get)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }
    public static func post(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.post)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }
    public static func put(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.put)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }
    public static func patch(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.patch)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }
    public static func delete(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.delete)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }
    public static func head(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.head)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }
    public static func options(
        url: URL,
        options: [HttpOption] = [],
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) -> Http {
        Http(
            request: URLRequest(url: url),
            options: [.method(.options)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }

    public convenience init(
        url: URL,
        options: [HttpOption] = [],
        urlSessionHandler: URLSessionHandler = .system,
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) {
        self.init(
            request: URLRequest(url: url),
            options: [.method(.options)] + options,
            onProgress: onProgress,
            onReceived: onReceived
        )
    }

    public init(
        request _request: URLRequest,
        options: [HttpOption] = [],
        urlSessionHandler: URLSessionHandler = .system,
        onProgress: OnProgressHandler? = nil,
        onReceived: @escaping OnReceivedHandler
    ) {
        var request = _request

        var isEphemeral = false
        var backgroundIdentifier: String?
        for option in options {
            option.apply(toRequest: &request)
            if case let .background(identifier) = option {
                backgroundIdentifier = identifier
                break
            }
            else if case .ephemeral = option {
                isEphemeral = false
                break
            }
            else if case let .body(body) = option {
                request.httpBody = body.toData
                break
            }
        }

        self.request = request

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

    public func map<T, U>(_ mapper: @escaping (T) -> U) -> Self {
        let command = self
        let myReceived = self.onReceived
        let onReceived: (HttpResult) -> U? = { result in
            myReceived(result).map { mapper($0 as! T) }
        }
        command.onReceived = onReceived

        if let myProgress = self.onProgress {
            let onProgress: (Float) -> U? = { result in
                myProgress(result).map { mapper($0 as! T) }
            }
            command.onProgress = onProgress
        }

        return command
    }

    public func cancel() {
        session.ashenCancel()
    }

    public func start(_ done: @escaping (AnyMessage) -> Void) {
        urlSessionDelegate.onReceived = { statusCode, headers, data, error in
            let result: HttpResult
            if let data = data {
                result = .ok((statusCode, headers, data))
            }
            else if let error = error {
                result = .fail(HttpError.system(statusCode, error))
            }
            else {
                result = .fail(HttpError.unknown(statusCode))
            }

            if let message = self.onReceived(result) {
                done(message)
            }
        }

        if let onProgress = onProgress {
            urlSessionDelegate.onProgress = { amt in
                onProgress(amt).map { done($0) }
            }
            startDownloadTask(request)
        }
        else {
            startDataTask(request)
        }
    }

    private func startDataTask(_ request: URLRequest) {
        let task = session.ashenDataTask(
            with: request,
            completionHandler: urlSessionDelegate.onReceived
        )
        task.ashenStart()
    }

    private func startDownloadTask(_ request: URLRequest) {
        let task = session.ashenDownloadTask(
            with: request,
            completionHandler: urlSessionDelegate.onReceived
        )
        task.ashenStart()
    }
}

extension Http.Delegate: URLSessionDelegate {
}
extension Http.Delegate: URLSessionTaskDelegate {
    // func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    //     guard let onReceived = onReceived, let error = error else { return }
    //     onReceived(nil, [], error)
    // }
}
extension Http.Delegate: URLSessionDataDelegate {
    // func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    // }
}
extension Http.Delegate: URLSessionDownloadDelegate {
    @available(OSX 10.9, *)
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo url: URL
    ) {
        // guard let onReceived = onReceived else { return }
        // if let data = try? Data(contentsOf: url, options: []) {
        //     onReceived(data, nil)
        // }
        // else {
        //     onReceived(nil, HttpError.noDataAtUrl(url))
        // }
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten totalWritten: Int64,
        totalBytesExpectedToWrite expected: Int64
    ) {
        guard expected > 0, Date().timeIntervalSince(lastSentProgress) > 0.1 else { return }
        onProgress?(Float(totalWritten) / Float(expected))
        lastSentProgress = Date()
    }
}
