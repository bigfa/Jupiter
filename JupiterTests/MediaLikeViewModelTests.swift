import XCTest
@testable import Jupiter

final class MediaLikeViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.requestHandler = nil
    }

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    @MainActor
    func testToggleSuccessUpdatesLikeState() async throws {
        URLProtocolStub.requestHandler = { request in
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
        URLProtocolStub.requestHandler = { request in
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
        let counter = RequestCounter()
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let currentCall = await counter.next()
            if currentCall == 1 {
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

    @MainActor
    func testLoadFailureFromInitialStateSetsErrorAndResetsLoading() async {
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/media/m_4/like")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":false,\"error\":\"Server busy\"}".utf8))
        }

        let viewModel = MediaLikeViewModel(mediaId: "m_4", service: makeService())
        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, "Server busy")
        XCTAssertEqual(viewModel.likes, 0)
        XCTAssertFalse(viewModel.liked)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testLatestRequestWinsWhenTwoLoadRequestsRace() async throws {
        let counter = RequestCounter()
        URLProtocolStub.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let currentCall = await counter.next()

            if currentCall == 1 {
                try await Task.sleep(nanoseconds: 300_000_000)
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data("{\"ok\":true,\"likes\":1,\"liked\":false}".utf8))
            } else {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data("{\"ok\":true,\"likes\":99,\"liked\":true}".utf8))
            }
        }

        let viewModel = MediaLikeViewModel(mediaId: "m_5", service: makeService())
        let first = Task { await viewModel.load() }
        try await Task.sleep(nanoseconds: 50_000_000)
        let second = Task { await viewModel.load() }

        await first.value
        await second.value

        XCTAssertEqual(viewModel.likes, 99)
        XCTAssertTrue(viewModel.liked)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    private func makeService() -> MediaService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        return MediaService(client: APIClient(session: session))
    }
}

private actor RequestCounter {
    private var count = 0

    func next() -> Int {
        count += 1
        return count
    }
}
