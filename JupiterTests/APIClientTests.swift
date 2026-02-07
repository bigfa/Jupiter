import XCTest
@testable import Jupiter

final class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.requestHandler = nil
    }

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func testGetBuildsQueryAndHeadersAndDecodesResponse() async throws {
        let client = makeClient()
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "1")
            XCTAssertEqual(request.url?.path, "/api/media/list")

            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "page", value: "2")))
            XCTAssertTrue(queryItems.contains(URLQueryItem(name: "pageSize", value: "20")))

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":true}".utf8))
        }

        let result: OKResponse = try await client.get(
            path: "/api/media/list",
            query: [
                .init(name: "page", value: "2"),
                .init(name: "pageSize", value: "20")
            ],
            headers: ["X-Test": "1"]
        )

        XCTAssertTrue(result.ok)
    }

    func testPostSetsContentTypeAndBody() async throws {
        let client = makeClient()
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.url?.path, "/api/albums/abc/unlock")

            let body = try XCTUnwrap(request.bodyData())
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(payload?["password"] as? String, "secret")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":true}".utf8))
        }

        _ = try await client.post(
            path: "/api/albums/abc/unlock",
            body: UnlockBody(password: "secret")
        ) as OKResponse
    }

    func testNon2xxDecodesAPIErrorPayload() async {
        let client = makeClient()
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data("{\"ok\":false,\"error\":\"Unauthorized\",\"code\":\"unauthorized\"}".utf8)
            return (response, data)
        }

        do {
            let _: OKResponse = try await client.get(path: "/api/media/1")
            XCTFail("Expected request to throw APIError")
        } catch let error as APIError {
            XCTAssertEqual(error.statusCode, 401)
            XCTAssertEqual(error.message, "Unauthorized")
            XCTAssertEqual(error.code, "unauthorized")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    private func makeClient() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return APIClient(session: URLSession(configuration: config))
    }
}

private struct OKResponse: Decodable {
    let ok: Bool
}

private struct UnlockBody: Encodable {
    let password: String
}

private final class URLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = URLProtocolStub.requestHandler else {
            fatalError("requestHandler was not set.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private extension URLRequest {
    func bodyData() -> Data? {
        if let httpBody {
            return httpBody
        }
        guard let stream = httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        let bufferSize = 1024
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                return nil
            }
            if read == 0 {
                break
            }
            data.append(buffer, count: read)
        }
        return data
    }
}
