import XCTest
@testable import Jupiter

final class MediaLikeViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MediaLikeURLProtocolStub.requestHandler = nil
    }

    override func tearDown() {
        MediaLikeURLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    @MainActor
    func testToggleSuccessUpdatesLikeState() async throws {
        MediaLikeURLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/media/m_1/like")
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":true,\"likes\":11,\"liked\":true}".utf8))
        }

        let viewModel = MediaLikeViewModel(mediaId: "m_1", service: makeService())
        await viewModel.toggle()

        XCTAssertEqual(viewModel.likes, 11)
        XCTAssertTrue(viewModel.liked)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testToggleFailureSetsErrorAndResetsLoading() async {
        MediaLikeURLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":false,\"error\":\"Like failed\"}".utf8))
        }

        let viewModel = MediaLikeViewModel(mediaId: "m_2", service: makeService())
        await viewModel.toggle()

        XCTAssertEqual(viewModel.errorMessage, "Like failed")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.likes, 0)
        XCTAssertFalse(viewModel.liked)
    }

    @MainActor
    func testLoadSuccessThenFailurePreservesStateAndUpdatesError() async {
        var callCount = 0
        MediaLikeURLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            callCount += 1
            if callCount == 1 {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data("{\"ok\":true,\"likes\":7,\"liked\":true}".utf8))
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":false,\"error\":\"Unauthorized\"}".utf8))
        }

        let viewModel = MediaLikeViewModel(mediaId: "m_3", service: makeService())
        await viewModel.load()

        XCTAssertEqual(viewModel.likes, 7)
        XCTAssertTrue(viewModel.liked)
        XCTAssertNil(viewModel.errorMessage)

        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, "Unauthorized")
        XCTAssertEqual(viewModel.likes, 7)
        XCTAssertTrue(viewModel.liked)
        XCTAssertFalse(viewModel.isLoading)
    }

    private func makeService() -> MediaService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MediaLikeURLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return MediaService(client: APIClient(session: session))
    }
}

private final class MediaLikeURLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("requestHandler must be set before starting URLProtocolStub.")
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
