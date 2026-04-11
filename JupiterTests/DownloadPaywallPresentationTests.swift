import XCTest
@testable import Jupiter

final class DownloadPaywallPresentationTests: XCTestCase {
    func testFeatureItemsKeepExpectedOrder() {
        let items = DownloadPaywallPresentation.featureItems()

        XCTAssertEqual(
            items.map(\.title),
            ["原图下载", "HDR 显示", "一次购买", "多设备恢复"]
        )
    }

    func testNoteItemsKeepExpectedOrder() {
        XCTAssertEqual(
            DownloadPaywallPresentation.noteItems(),
            [
                "由 Apple App Store 安全支付",
                "同一 Apple ID 可恢复购买",
                "不会加入广告或隐藏追踪"
            ]
        )
    }

    func testStatusBadgeReflectsPurchaseState() {
        XCTAssertEqual(
            DownloadPaywallPresentation.statusBadge(isPurchased: true),
            "已解锁"
        )
        XCTAssertEqual(
            DownloadPaywallPresentation.statusBadge(isPurchased: false),
            "未解锁"
        )
    }
}
