////
///  Http.swift
//

import Foundation

public struct HttpRequest<Msg> {
    let httpPrivateRequest: HttpPrivateRequest?
    public let cancel: () -> Void

    public typealias OnProgressHandler<Msg> = (Float) -> Msg
    public typealias OnCompleteHandler<Msg> = (Http.Result) -> Msg

    public static func get(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.get)] + options
        )
    }
    public static func post(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.post)] + options
        )
    }
    public static func put(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.put)] + options
        )
    }
    public static func patch(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.patch)] + options
        )
    }
    public static func delete(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.delete)] + options
        )
    }
    public static func head(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.head)] + options
        )
    }
    public static func options(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) -> HttpRequest {
        HttpRequest(
            url: url,
            options: [.method(.options)] + options
        )
    }

    public init(
        url: URLRequestConvertible,
        options: [Http.Option] = []
    ) {
        if let urlRequest = url.toURLRequest() {
            let httpPrivateRequest = HttpPrivateRequest(
                request: urlRequest,
                options: options)
            self.cancel = {
                httpPrivateRequest.cancel()
            }
            self.httpPrivateRequest = httpPrivateRequest
        }
        else {
            self.httpPrivateRequest = nil
            self.cancel = {}
        }
    }

    public func decodeJson<T>(_ type: T.Type) -> HttpMappedRequest<Msg, T> where T : Decodable {
        HttpMappedRequest<Msg, T>(httpRequest: self, map: { response in
            let (_, _, data) = response
            let coder = JSONDecoder()
            return try coder.decode(type, from: data)
        })
    }

    public func mapResponse<T>(_ map: @escaping (Http.Response) throws -> T) -> HttpMappedRequest<Msg, T> {
        HttpMappedRequest<Msg, T>(httpRequest: self, map: { response in
            return try map(response)
        })
    }

    public func start(
        onComplete: @escaping OnCompleteHandler<Msg>,
        onProgress: OnProgressHandler<Msg>? = nil
    )
        -> Command<Msg>
    {
        guard let httpPrivateRequest = self.httpPrivateRequest else {
            return Command { send in
                send(onComplete(.failure(.invalidURL)))
            }
        }

        return Command { send in
            httpPrivateRequest.start(
                onComplete: { result in
                    send(onComplete(result))
                },
                onProgress: onProgress.map({ progressMsg in
                    { progress in
                        send(progressMsg(progress))
                    }
                })
            )
        }
    }
}

public struct HttpMappedRequest<Msg, T> {
    public typealias Result = Swift.Result<T, Http.Error>
    let httpRequest: HttpRequest<Msg>
    let map: (Http.Response) throws -> T

    public typealias OnProgressHandler<Msg> = (Float) -> Msg
    public typealias OnCompleteHandler<Msg> = (Result) -> Msg

    public func cancel() {
        httpRequest.cancel()
    }

    public func start(
        onComplete: @escaping OnCompleteHandler<Msg>,
        onProgress: OnProgressHandler<Msg>? = nil
    )
        -> Command<Msg>
    {
        httpRequest.start(
            onComplete: { result in
                do {
                    let value = try result.get()
                    let mapped = try self.map(value)
                    return onComplete(.success(mapped))
                } catch {
                    if let error = error as? Http.Error {
                        return onComplete(.failure(error))
                    }
                    else {
                        return onComplete(.failure(Http.Error.system(error)))
                    }
                }
            },
            onProgress: onProgress
        )
    }
}

public struct Http {
    public typealias Response = (Int, [Header], Data)
    public typealias Result = Swift.Result<Response, Error>

    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }

    public struct Header {
        public let name: String
        public let value: String

        public init(name: Name, value: String) {
            self.name = name.rawValue
            self.value = value
        }

        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }

        public enum Name: String {
            case contentType = "Content-Type"
        }

        public func `is`(_ other: Name) -> Bool {
            name.lowercased() == other.rawValue.lowercased()
        }
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

    public enum Error: Swift.Error {
        case invalidURL
        case status(Int, Swift.Error)
        case system(Swift.Error)
        case noDataAtURL(Int, URL)
        case decoding(Swift.Error)
        case unknown(Int, [Header])
    }

    public enum Option {
        // mixing concerns here, but it's easy & handy to have these as a generic "options"
        // array rather than lots of optional arguments.

        // can be .system or .mock((URLSessionConfiguration) -> URLSessionProtocol)
        case sessionHandler(SessionHandler)

        // Background & ephemeral control what
        // type of URLSessionConfiguration object is created.
        case background(String)
        case ephemeral

        // URLRequest
        case method(Http.Method)
        case body(Http.Body)
        case headers([Header])
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
    }

    public enum SessionHandler {
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
}

class HttpPrivateRequest {
    typealias OnProgressHandler = (Float) -> Void
    typealias OnCompleteHandler = (Http.Result) -> Void
    typealias OnDelegateCompleteHandler = ((Int, [Http.Header], Data?, Swift.Error?) -> Void)

    class Delegate: NSObject {
        var lastSentProgress = Date()
        var onComplete: OnDelegateCompleteHandler?
        var onProgress: OnProgressHandler?
    }

    let urlSessionDelegate = Delegate()
    let request: URLRequest
    let session: URLSessionProtocol
    var onProgress: OnProgressHandler?
    var onComplete: OnCompleteHandler?

    init(
        request _request: URLRequest,
        options: [Http.Option] = []
    ) {
        var request = _request
        var configOpt: URLSessionConfiguration?
        var sessionHandlerOpt: Http.SessionHandler?
        for option in options {
            option.apply(toRequest: &request)
            if case let .background(identifier) = option {
                configOpt = .background(withIdentifier: identifier)
            }
            else if case .ephemeral = option {
                configOpt = .ephemeral
            }
            else if case let .body(body) = option {
                request.httpBody = body.toData
            }
            else if case let .sessionHandler(sessionHandler) = option {
                sessionHandlerOpt = sessionHandler
            }
        }

        self.request = request
        self.onProgress = nil
        self.onComplete = nil

        let config = configOpt ?? .default
        for option in options {
            option.apply(toConfig: config)
        }

        let sessionHandler = sessionHandlerOpt ?? .system
        self.session = sessionHandler.create(config: config, delegate: urlSessionDelegate)
        // This method is stubbed out below but is a no-op. Commenting out for now.
        // for option in options {
        //     option.apply(toSession: session)
        // }
    }

    func cancel() {
        session.ashenCancel()
    }

    func start(
        onComplete: @escaping OnCompleteHandler,
        onProgress: OnProgressHandler? = nil
    ) {
        self.onProgress = onProgress
        self.onComplete = onComplete

        urlSessionDelegate.onComplete = { statusCode, headers, data, error in
            let result: Http.Result
            if let data = data {
                result = .success((statusCode, headers, data))
            }
            else if let error = error {
                result = .failure(.status(statusCode, error))
            }
            else {
                result = .failure(.unknown(statusCode, headers))
            }

            onProgress?(1)
            onComplete(result)
        }

        if let onProgress = onProgress {
            urlSessionDelegate.onProgress = { amt in
                onProgress(amt)
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
            completionHandler: urlSessionDelegate.onComplete
        )
        task.ashenStart()
    }

    private func startDownloadTask(_ request: URLRequest) {
        let task = session.ashenDownloadTask(
            with: request,
            completionHandler: urlSessionDelegate.onComplete
        )
        task.ashenStart()
    }

}

extension HttpPrivateRequest.Delegate: URLSessionDelegate {}

extension HttpPrivateRequest.Delegate: URLSessionTaskDelegate {
    // func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    //     guard let onComplete = onComplete, let error = error else { return }
    //     onComplete(nil, [], error)
    // }
}

extension HttpPrivateRequest.Delegate: URLSessionDataDelegate {
    // func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    // }
}

extension HttpPrivateRequest.Delegate: URLSessionDownloadDelegate {
    @available(OSX 10.9, *)
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo url: URL
    ) {
        // guard let onComplete = onComplete else { return }
        // if let data = try? Data(contentsOf: url, options: []) {
        //     onComplete(data, nil)
        // }
        // else {
        //     onComplete(nil, .noDataAtURL(url))
        // }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten totalWritten: Int64,
        totalBytesExpectedToWrite expected: Int64
    ) {
        guard expected > 0, Date().timeIntervalSince(lastSentProgress) > 0.016 else { return }
        onProgress?(Float(totalWritten) / Float(expected))
        lastSentProgress = Date()
    }
}

private func responseToHeaders(_ response: URLResponse?) -> [Http.Header] {
    guard let response = response as? HTTPURLResponse else { return [] }
    return response.allHeaderFields.compactMap { name, value -> Http.Header? in
        guard let name = name as? String, let value = value as? String else { return nil }
        return Http.Header(name: name, value: value)
    }
}

public protocol URLSessionProtocol: class {
    func ashenDataTask(with: URLRequest, completionHandler: ((Int, [Http.Header], Data?, Swift.Error?) -> Void)?)
        -> URLSessionTaskProtocol
    func ashenDownloadTask(with: URLRequest, completionHandler: ((Int, [Http.Header], Data?, Swift.Error?) -> Void)?)
        -> URLSessionTaskProtocol
    func ashenCancel()
}

extension URLSession: URLSessionProtocol {
    public func ashenDataTask(
        with request: URLRequest,
        completionHandler: ((Int, [Http.Header], Data?, Swift.Error?) -> Void)?
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
        completionHandler: ((Int, [Http.Header], Data?, Swift.Error?) -> Void)?
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

extension Http.Option {
    func apply(toConfig config: URLSessionConfiguration) {
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

    func apply(toRequest request: inout URLRequest) {
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

    // func apply(toSession session: URLSessionProtocol) {
    // }
}

public protocol URLRequestConvertible {
    func toURLRequest() -> URLRequest?
}

extension String: URLRequestConvertible {
    public func toURLRequest() -> URLRequest? {
        URL(string: self)?.toURLRequest()
    }
}

extension URL: URLRequestConvertible {
    public func toURLRequest() -> URLRequest? {
        URLRequest(url: self)
    }
}

extension URLRequest: URLRequestConvertible {
    public func toURLRequest() -> URLRequest? {
        self
    }
}
