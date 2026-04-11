import XCTest
@testable import Jupiter

final class FeedPresentationTests: XCTestCase {
    func testCurrentYearUsesShortDateTitle() {
        let now = ISO8601DateFormatter().date(from: "2026-04-10T00:00:00Z")!
        let title = FeedPresentation.formattedSectionTitle(
            from: "2026-04-02T11:22:33.000Z",
            now: now
        )

        XCTAssertEqual(title, "Apr 02")
    }

    func testPastYearUsesLongDateTitle() {
        let now = ISO8601DateFormatter().date(from: "2026-04-10T00:00:00Z")!
        let title = FeedPresentation.formattedSectionTitle(
            from: "2025:05:31 03:07:18",
            now: now
        )

        XCTAssertEqual(title, "May 31, 2025")
    }
}
