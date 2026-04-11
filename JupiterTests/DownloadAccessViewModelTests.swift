import XCTest
@testable import Jupiter

final class DownloadAccessViewModelTests: XCTestCase {
    func testPurchaseButtonTitleFallsBackToOneTimePurchase() {
        XCTAssertEqual(
            DownloadEntitlementPresentation.purchaseButtonTitle(priceText: nil),
            String(localized: "One-time purchase")
        )
    }

    func testPurchaseButtonTitleIncludesPriceWhenAvailable() {
        let expected = String(
            format: String(localized: "One-time purchase (%@)"),
            locale: Locale.current,
            "$0.99"
        )
        XCTAssertEqual(
            DownloadEntitlementPresentation.purchaseButtonTitle(priceText: "$0.99"),
            expected
        )
    }

    func testBenefitStatusUsesUnlockedAndLockedCopy() {
        XCTAssertEqual(
            DownloadEntitlementPresentation.benefitStatusText(isPurchased: true),
            String(localized: "Unlocked")
        )
        XCTAssertEqual(
            DownloadEntitlementPresentation.benefitStatusText(isPurchased: false),
            String(localized: "Locked")
        )
    }
}
