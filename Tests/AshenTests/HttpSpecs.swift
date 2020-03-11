////
///  HttpSpecs.swift
//

import Foundation
@testable import Ashen

struct HttpSpecs: Spec {
    var name: String { "HttpSpecs" }

    class MockSession: URLSessionProtocol {
        var cancelled = 0
        var request: URLRequest?

        func ashenDataTask(
            with request: URLRequest,
            completionHandler: Http.Delegate.OnReceivedHandler?
        ) -> URLSessionTaskProtocol {
            self.request = request
            return MockSessionTask()
        }

        func ashenDownloadTask(
            with request: URLRequest,
            completionHandler: Http.Delegate.OnReceivedHandler?
        ) -> URLSessionTaskProtocol {
            self.request = request
            return MockSessionTask()
        }

        func ashenCancel() {
            cancelled += 1
        }
    }

    class MockSessionTask: URLSessionTaskProtocol {
        var started = 0

        func ashenStart() {
            started += 1
        }
    }

    func run(expect: (String) -> Expectations, done: @escaping () -> Void) {
        var config: URLSessionConfiguration?

        let mockSession = MockSession()
        let url = URL(string: "https://github.com")!
        let subject = Http(
            request: URLRequest(url: url),
            options: [
                .method(.post),
                .timeout(1),
                .header("Bearer-Token", "abcdef")
            ],
            urlSessionHandler: .mock({ newConfig in
                config = newConfig
                return mockSession
            }),
            onReceived: { _ in
                "message!"
            }
        )
        let request = subject.request
        expect("configures timeout")
            .assert(config != nil)
            .assertEqual(config?.timeoutIntervalForResource, 1)
        expect("configures httpMethod")
            .assertEqual(request.httpMethod, "POST")
        expect("configures headers")
            .assertEqual(request.allHTTPHeaderFields?["Bearer-Token"], "abcdef" as String?)

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
