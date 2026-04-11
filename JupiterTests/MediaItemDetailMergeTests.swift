import XCTest
@testable import Jupiter

final class MediaItemDetailMergeTests: XCTestCase {
    func testDetailMergeRestoresMetadataFieldsFromDetailResponse() {
        let preview = MediaItem(
            id: "m1",
            url: "https://example.com/preview.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: 12,
            liked: true,
            datetimeOriginal: nil,
            createdAt: "2026-02-05T07:10:11.244Z",
            filename: nil,
            size: nil,
            mimeType: nil,
            cameraMake: nil,
            cameraModel: nil,
            lensModel: nil,
            aperture: nil,
            shutterSpeed: nil,
            iso: nil,
            focalLength: nil,
            locationName: nil,
            gpsLat: nil,
            gpsLon: nil,
            tags: nil,
            categories: nil
        )

        let detail = MediaDetail(
            id: "m1",
            url: "https://example.com/detail.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            filename: "detail.jpg",
            size: 2048,
            mimeType: "image/jpeg",
            width: 724,
            height: 1086,
            createdAt: "2026-02-05T07:10:11.244Z",
            cameraMake: "Fujifilm",
            cameraModel: "X100VI",
            lensModel: "23mm",
            aperture: "f/2.0",
            shutterSpeed: "1/125",
            iso: "400",
            focalLength: "23mm",
            datetimeOriginal: "2025:05:31 03:07:18",
            locationName: "Tokyo",
            gpsLat: 35.6762,
            gpsLon: 139.6503,
            tags: ["street"],
            categories: [MediaCategory(id: "travel", name: "Travel")]
        )

        let merged = MediaItem(detail: detail, fallback: preview)

        XCTAssertEqual(merged.id, "m1")
        XCTAssertEqual(merged.url, "https://example.com/detail.jpg")
        XCTAssertEqual(merged.likes, 12)
        XCTAssertEqual(merged.liked, true)
        XCTAssertEqual(merged.cameraModel, "X100VI")
        XCTAssertEqual(merged.aperture, "f/2.0")
        XCTAssertEqual(merged.shutterSpeed, "1/125")
        XCTAssertEqual(merged.iso, "400")
        XCTAssertEqual(merged.focalLength, "23mm")
        XCTAssertEqual(merged.datetimeOriginal, "2025:05:31 03:07:18")
        XCTAssertEqual(merged.locationName, "Tokyo")
        XCTAssertEqual(merged.tags, ["street"])
        XCTAssertEqual(merged.categories?.first?.name, "Travel")
    }
}
