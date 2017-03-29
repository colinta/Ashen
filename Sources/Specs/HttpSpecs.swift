////
///  HttpSpecs.swift
//

import Foundation


struct HttpSpecs: Spec {
    var name: String { return "HttpSpecs" }

    class MockSession: URLSessionProtocol {
        var cancelled = 0
        var request: URLRequest?

        func ashen_dataTask(with request: URLRequest) -> URLSessionTaskProtocol {
            self.request = request
            return MockSessionTask()
        }

        func ashen_downloadTask(with request: URLRequest) -> URLSessionTaskProtocol {
            self.request = request
            return MockSessionTask()
        }

        func ashen_cancel() {
            cancelled += 1
        }
    }

    class MockSessionTask: URLSessionTaskProtocol {
        var started = 0

        func ashen_start() {
            started += 1
        }
    }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        var config: URLSessionConfiguration?

        let mockSession = MockSession()
        let url = URL(string: "https://github.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let subject = Http(
            request: request,
            options: [.timeout(1), .header("Bearer-Token", "abcdef")],
            urlSessionHandler: .mock({ newConfig in
                config = newConfig
                return mockSession
            }),
            onReceived: { _ in
                return "message!"
            })
        expect("configures timeout")
            .assert(config != nil)
            .assertEqual(config?.timeoutIntervalForResource, 1)
        expect("configures headers")
            .assertEqual(config?.httpAdditionalHeaders?["Bearer-Token"] as? String, "abcdef" as String?)

        var messages: [String] = []
        subject.start() { msg in
            (msg as? String).map { messages.append($0) }
        }

        expect("receives request")
            .assert(mockSession.request != nil)
            .assertEqual(mockSession.request?.httpMethod, "POST")
        done()
    }
}
