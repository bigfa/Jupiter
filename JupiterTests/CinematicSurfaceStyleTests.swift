import XCTest
@testable import Jupiter

final class CinematicSurfaceStyleTests: XCTestCase {
    func testFloatingControlUsesExpectedCornerRadiusAndShadow() {
        let style = CinematicSurfaceStyle.floatingControl

        XCTAssertEqual(style.cornerRadius, 22)
        XCTAssertEqual(style.horizontalPadding, 14)
        XCTAssertEqual(style.verticalPadding, 10)
        XCTAssertEqual(style.shadowRadius, 10)
    }

    func testSelectedTabHasStrongerForegroundAndFill() {
        let selectedStyle = CinematicSurfaceStyle.tab(selected: true)
        let idleStyle = CinematicSurfaceStyle.tab(selected: false)

        XCTAssertGreaterThan(selectedStyle.foregroundOpacity, idleStyle.foregroundOpacity)
        XCTAssertGreaterThan(selectedStyle.fillOpacity, idleStyle.fillOpacity)
        XCTAssertGreaterThan(selectedStyle.strokeOpacity, idleStyle.strokeOpacity)
    }
}
