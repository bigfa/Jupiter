import XCTest
@testable import Jupiter

@MainActor
final class MediaMetadataPresentationTests: XCTestCase {
    func testCardHeightUsesCompactPresentationRatio() {
        XCTAssertEqual(
            MediaMetadataPresentation.cardHeight(for: 900),
            252,
            accuracy: 1
        )
    }

    func testViewerCardHeightUsesBalancedDefaultRatio() {
        XCTAssertEqual(
            MediaMetadataPresentation.viewerCardHeight(for: 956),
            268,
            accuracy: 1
        )
    }

    func testViewerCardHeightExpandsForDenseMetadataContent() {
        let item = MediaItem(
            id: "m1",
            url: "https://example.com/photo.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: nil,
            liked: nil,
            datetimeOriginal: "2025:05:31 03:07:18",
            createdAt: nil,
            filename: nil,
            size: nil,
            mimeType: "image/jpeg",
            cameraMake: "FUJIFILM",
            cameraModel: "X100VI",
            lensModel: "23mm F2",
            aperture: "f/2.0",
            shutterSpeed: "1/125",
            iso: "400",
            focalLength: "23mm",
            locationName: "Shanghai",
            gpsLat: 31.2304,
            gpsLon: 121.4737,
            tags: ["travel", "night"],
            categories: [
                MediaCategory(id: "street", name: "Street")
            ]
        )

        XCTAssertEqual(
            MediaMetadataPresentation.viewerCardHeight(
                for: 956,
                item: item,
                isDetailLoading: false,
                bottomSafeInset: 34
            ),
            497,
            accuracy: 1
        )
    }

    func testFittedCardHeightShrinksForShortContent() {
        XCTAssertEqual(
            MediaMetadataPresentation.fittedCardHeight(
                viewportHeight: 900,
                contentHeight: 110,
                bottomSafeInset: 34
            ),
            206,
            accuracy: 1
        )
    }

    func testFittedCardHeightAllowsMoreMetadataRowsBeforeClamping() {
        XCTAssertEqual(
            MediaMetadataPresentation.fittedCardHeight(
                viewportHeight: 900,
                contentHeight: 350,
                bottomSafeInset: 34
            ),
            446,
            accuracy: 1
        )
    }

    func testGridRowCountKeepsTwoColumnRhythm() {
        XCTAssertEqual(MediaMetadataPresentation.gridRowCount(for: 1), 1)
        XCTAssertEqual(MediaMetadataPresentation.gridRowCount(for: 2), 1)
        XCTAssertEqual(MediaMetadataPresentation.gridRowCount(for: 3), 2)
        XCTAssertEqual(MediaMetadataPresentation.gridRowCount(for: 5), 3)
    }

    func testCardRowsGroupMetadataIntoTwoColumnLines() {
        let rows = MediaMetadataPresentation.rows(
            for: [
                MediaMetadataCardItem(field: .camera, value: "GR IV"),
                MediaMetadataCardItem(field: .shutter, value: "1/200"),
                MediaMetadataCardItem(field: .focalLength, value: "18.3 mm")
            ]
        )

        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0].map(\.field), [.camera, .shutter])
        XCTAssertEqual(rows[1].map(\.field), [.focalLength])
    }

    func testGridItemWidthSplitsContainerIntoTwoColumns() {
        XCTAssertEqual(
            MediaMetadataPresentation.gridItemWidth(containerWidth: 360),
            175,
            accuracy: 0.5
        )
    }


    func testCardsUseAllowedFieldsAndHideFileMetadata() {
        let item = MediaItem(
            id: "m1",
            url: "https://example.com/photo.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: nil,
            liked: nil,
            datetimeOriginal: "2025:05:31 03:07:18",
            createdAt: "2026-02-05T07:10:11.244Z",
            filename: "secret.jpg",
            size: 1024,
            mimeType: nil,
            cameraMake: "RICOH",
            cameraModel: "GR IV",
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

        let cards = MediaMetadataPresentation.cards(for: item)

        XCTAssertEqual(cards.map(\.field), [.camera, .shootTime])
        XCTAssertEqual(cards.map(\.value), ["GR IV", "2025-05-31"])
    }

    func testCardsBuildReadableCoordinateValue() {
        let item = MediaItem(
            id: "m1",
            url: "https://example.com/photo.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: nil,
            liked: nil,
            datetimeOriginal: nil,
            createdAt: nil,
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
            gpsLat: 31.2304,
            gpsLon: 121.4737,
            tags: nil,
            categories: nil
        )

        let cards = MediaMetadataPresentation.cards(for: item)

        XCTAssertEqual(cards.first?.field, .gps)
        XCTAssertEqual(cards.first?.value, "31.23040, 121.47370")
    }

    func testContentStateUsesSkeletonWhenDetailIsLoadingAndMetadataIsEmpty() {
        let item = MediaItem(
            id: "m1",
            url: "https://example.com/photo.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: nil,
            liked: nil,
            datetimeOriginal: nil,
            createdAt: nil,
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

        XCTAssertEqual(
            MediaMetadataPresentation.contentState(item: item, isDetailLoading: true),
            .loadingSkeleton
        )
    }

    func testContentStateShowsContentWhenPreviewAlreadyHasMetadata() {
        let item = MediaItem(
            id: "m1",
            url: "https://example.com/photo.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: nil,
            liked: nil,
            datetimeOriginal: "2025:05:31 03:07:18",
            createdAt: nil,
            filename: nil,
            size: nil,
            mimeType: nil,
            cameraMake: nil,
            cameraModel: "X100VI",
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

        XCTAssertEqual(
            MediaMetadataPresentation.contentState(item: item, isDetailLoading: true),
            .content
        )
    }

    func testContentStateFallsBackToEmptyAfterLoadingCompletesWithoutMetadata() {
        let item = MediaItem(
            id: "m1",
            url: "https://example.com/photo.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 724,
            height: 1086,
            likes: nil,
            liked: nil,
            datetimeOriginal: nil,
            createdAt: nil,
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

        XCTAssertEqual(
            MediaMetadataPresentation.contentState(item: item, isDetailLoading: false),
            .empty
        )
    }
}
