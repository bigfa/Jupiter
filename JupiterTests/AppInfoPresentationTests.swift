import XCTest
@testable import Jupiter

final class AppInfoPresentationTests: XCTestCase {
    func testLockedAccessCardUsesUpgradeCopy() {
        let card = AppInfoPresentation.accessCard(isPurchased: false)

        XCTAssertEqual(card.title, "下载权益")
        XCTAssertEqual(card.status, "未解锁")
        XCTAssertEqual(card.summary, "一次购买后即可永久下载原图，并解锁 HDR 照片显示。")
        XCTAssertEqual(card.actionTitle, "查看权益")
    }

    func testUnlockedAccessCardUsesAvailableCopy() {
        let card = AppInfoPresentation.accessCard(isPurchased: true)

        XCTAssertEqual(card.title, "下载权益")
        XCTAssertEqual(card.status, "已解锁")
        XCTAssertEqual(card.summary, "原图下载与 HDR 照片显示已可用，可直接进入查看权益详情。")
        XCTAssertEqual(card.actionTitle, "查看详情")
    }

    func testPrimaryInfoCardsKeepExpectedOrder() {
        let cards = AppInfoPresentation.primaryCards()

        XCTAssertEqual(cards.map(\.title), ["联系作者", "隐私政策", "服务条款"])
        XCTAssertEqual(cards.map(\.systemImage), ["envelope.badge", "hand.raised", "doc.text"])
    }
}
