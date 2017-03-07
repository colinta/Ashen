////
///  HttpSpecs.swift
//

import Foundation


struct HttpSpecs: Spec {
    var name: String { return "HttpSpecs" }
    class MockSession: URLSessionProtocol {
        var cancelled = 0
        var request: URLRequest?
        var completionHandler: URLSessionCompletionHandler?

        func ashen_dataTask(with request: URLRequest, completionHandler: @escaping URLSessionCompletionHandler) -> URLSessionTaskProtocol {
            self.request = request
            self.completionHandler = completionHandler
            return MockSessionTask()
        }

        func ashen_cancel() {
            cancelled += 1
        }

        func mockCompleted(_ data: Data? = nil, _ response: URLResponse? = nil, error: Error? = nil) {
            completionHandler?(data, response, error)
        }
    }

    class MockSessionTask: URLSessionTaskProtocol {
        var started = 0

        func ashen_start() {
            started += 1
        }
    }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        var config: URLSessionConfiguration?

        let mockSession = MockSession()
        let url = URL(string: "https://github.com")!
        let method: HttpMethod = .post
        let subject = Http(
            url: url,
            method: method,
            options: [.timeout(1), .header("Bearer-Token", "abcdef")],
            urlSessionHandler: .mock({ newConfig in
                config = newConfig
                return mockSession
            }),
            onReceived: { result in
                switch result {
                case let .ok(newData, newResponse):
                    data = newData
                    response = newResponse
                case let .fail(newError):
                    error = newError
                }
                return nil
            })
        expect("configures timeout")
            .assert(config != nil)
            .assertEqual(config?.timeoutIntervalForResource, 1)
        expect("configures headers")
            .assertEqual(config?.httpAdditionalHeaders?["Bearer-Token"] as? String, "abcdef" as String?)

        var messages: [AnyMessage] = []
        subject.start() { msg in
            messages.append(msg)
        }
        expect("receives request")
            .assert(mockSession.request != nil)
            .assertEqual(mockSession.request?.httpMethod, method.rawValue)

        mockSession.mockCompleted(Data(), URLResponse(url: url, mimeType: "x-mock/testing", expectedContentLength: 0, textEncodingName: nil))
        expect("receives data").assert(data != nil)
        expect("receives response").assert(response != nil)
        expect("receives error").assert(error == nil)
        done()
    }
}
