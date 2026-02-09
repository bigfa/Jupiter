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

    func testMediaLikeUsesPostWithJSONBodyAndContentType() async throws {
        let service = MediaService(client: makeClient())
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/media/m_9/like")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try XCTUnwrap(request.bodyData())
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            XCTAssertEqual(payload?["action"] as? String, "like")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":true,\"likes\":9,\"liked\":true}".utf8))
        }

        let result = try await service.likeMedia(id: "m_9")
        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.likes, 9)
        XCTAssertTrue(result.liked)
    }

    func testMediaUnlikeUsesDeleteWithNoRequestBody() async throws {
        let service = MediaService(client: makeClient())
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            XCTAssertEqual(request.url?.path, "/api/media/m_9/like")
            XCTAssertNil(request.httpBody)
            XCTAssertNil(request.bodyData())

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":true,\"likes\":8,\"liked\":false}".utf8))
        }

        let result = try await service.unlikeMedia(id: "m_9")
        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.likes, 8)
        XCTAssertFalse(result.liked)
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
