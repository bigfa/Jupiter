import XCTest
import SwiftUI
@testable import Jupiter

final class MediaViewerPresentationTests: XCTestCase {
    func testStartIndexResolvesMatchingMediaId() {
        let items = [
            MediaItem(id: "a", url: "https://example.com/a.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: nil, liked: nil, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil),
            MediaItem(id: "b", url: "https://example.com/b.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: nil, liked: nil, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil),
            MediaItem(id: "c", url: "https://example.com/c.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: nil, liked: nil, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil)
        ]

        XCTAssertEqual(
            MediaViewerPresentation.startIndex(items: items, startId: "b"),
            1
        )
    }

    func testStartIndexFallsBackToFirstItemWhenIdIsMissing() {
        let items = [
            MediaItem(id: "a", url: "https://example.com/a.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: nil, liked: nil, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil),
            MediaItem(id: "b", url: "https://example.com/b.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: nil, liked: nil, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil)
        ]

        XCTAssertEqual(
            MediaViewerPresentation.startIndex(items: items, startId: "missing"),
            0
        )
    }


    func testNeighboringIndexResolvesWithinBounds() {
        XCTAssertEqual(
            MediaViewerPresentation.neighboringIndex(currentIndex: 1, direction: .next, itemCount: 3),
            2
        )
        XCTAssertEqual(
            MediaViewerPresentation.neighboringIndex(currentIndex: 1, direction: .previous, itemCount: 3),
            0
        )
    }

    func testNeighboringIndexReturnsNilAtBounds() {
        XCTAssertNil(
            MediaViewerPresentation.neighboringIndex(currentIndex: 0, direction: .previous, itemCount: 3)
        )
        XCTAssertNil(
            MediaViewerPresentation.neighboringIndex(currentIndex: 2, direction: .next, itemCount: 3)
        )
    }

    func testSelectionNearEndRequestsMorePages() {
        XCTAssertTrue(
            MediaViewerPresentation.shouldRequestMore(afterSelecting: 8, itemCount: 10)
        )
        XCTAssertFalse(
            MediaViewerPresentation.shouldRequestMore(afterSelecting: 6, itemCount: 10)
        )
    }

    func testOnlyVisiblePageActivatesHeavyDetailWork() {
        XCTAssertTrue(
            MediaViewerPresentation.shouldActivatePage(pageIndex: 3, selectedIndex: 3)
        )
        XCTAssertFalse(
            MediaViewerPresentation.shouldActivatePage(pageIndex: 2, selectedIndex: 3)
        )
        XCTAssertFalse(
            MediaViewerPresentation.shouldActivatePage(pageIndex: 4, selectedIndex: 3)
        )
    }

    func testAspectFitRectCentersPortraitImage() {
        let rect = MediaViewerPresentation.aspectFitRect(
            imageSize: CGSize(width: 724, height: 1086),
            containerSize: CGSize(width: 393, height: 852)
        )

        XCTAssertEqual(rect.midX, 196.5, accuracy: 0.5)
        XCTAssertEqual(rect.midY, 426, accuracy: 0.5)
    }

    func testDismissDragRequiresDownwardMotionAndCollapsedMetadata() {
        XCTAssertTrue(MediaViewerPresentation.shouldDismissPhoto(
            translationY: 130,
            predictedTranslationY: 260,
            zoomScale: 1,
            metadataState: .collapsed
        ))

        XCTAssertFalse(MediaViewerPresentation.shouldDismissPhoto(
            translationY: 130,
            predictedTranslationY: 260,
            zoomScale: 1,
            metadataState: .medium
        ))
    }

    func testChromeTopPaddingAddsSafeAreaSpacing() {
        XCTAssertEqual(MediaViewerPresentation.chromeTopPadding(safeTopInset: 59), 83, accuracy: 0.1)
        XCTAssertEqual(MediaViewerPresentation.chromeTopPadding(safeTopInset: 0), 56, accuracy: 0.1)
    }

    func testHorizontalPagingProducesDirectionalOffsets() {
        XCTAssertEqual(
            MediaViewerPresentation.pageOffsets(direction: .next, width: 393).outbound,
            -393,
            accuracy: 0.1
        )
        XCTAssertEqual(
            MediaViewerPresentation.pageOffsets(direction: .previous, width: 393).outbound,
            393,
            accuracy: 0.1
        )
    }

    func testHeroRestingFrameUsesFullCanvasCentering() {
        let frame = MediaViewerPresentation.heroRestingFrame(
            imageSize: CGSize(width: 724, height: 1086),
            viewportSize: CGSize(width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        )

        XCTAssertEqual(frame.midY, 472.5, accuracy: 0.5)
    }

    func testHeroRestingFrameKeepsMidXStableWithHorizontalSafeArea() {
        let frame = MediaViewerPresentation.heroRestingFrame(
            imageSize: CGSize(width: 1600, height: 900),
            viewportSize: CGSize(width: 852, height: 393),
            safeAreaInsets: EdgeInsets(top: 0, leading: 44, bottom: 0, trailing: 44)
        )

        XCTAssertEqual(frame.midX, 426, accuracy: 0.5)
    }

    func testLandscapeHeroFrameStillCentersOnFullCanvas() {
        let frame = MediaViewerPresentation.heroRestingFrame(
            imageSize: CGSize(width: 1600, height: 900),
            viewportSize: CGSize(width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        )

        XCTAssertEqual(frame.midX, 196.5, accuracy: 0.5)
    }

    func testHeroRestingPositionMapsFullCanvasFrameIntoViewportCoordinates() {
        let position = MediaViewerPresentation.heroRestingPosition(
            imageSize: CGSize(width: 724, height: 1086),
            viewportSize: CGSize(width: 393, height: 852),
            safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
        )

        XCTAssertEqual(position.x, 196.5, accuracy: 0.5)
        XCTAssertEqual(position.y, 413.5, accuracy: 0.5)
    }

    func testChromeButtonsRespectSafeAreaAndOuterMargin() {
        XCTAssertEqual(MediaViewerPresentation.chromeButtonTopInset(safeTopInset: 59), 71, accuracy: 0.5)
    }

    func testChromeButtonsUseFallbackPaddingWhenSafeAreaIsMissing() {
        XCTAssertEqual(MediaViewerPresentation.chromeButtonTopInset(safeTopInset: 0), 56, accuracy: 0.5)
    }

    func testMetadataOpenPreventsPhotoDismiss() {
        XCTAssertFalse(MediaViewerPresentation.shouldDismissPhoto(
            translationY: 140,
            predictedTranslationY: 300,
            zoomScale: 1,
            metadataState: .medium
        ))
    }

    func testMetadataOpenStateUsesPhotoFirstDismissBehavior() {
        XCTAssertTrue(
            MediaViewerPresentation.photoDragShouldCollapseMetadata(
                translationY: 120,
                metadataState: .medium
            )
        )

        XCTAssertFalse(
            MediaViewerPresentation.photoDragShouldCollapseMetadata(
                translationY: 120,
                metadataState: .collapsed
            )
        )
    }


    func testMetadataVisibleDragUsesDampedPhotoOffset() {
        let offset = MediaViewerPresentation.photoDragOffset(
            translation: CGSize(width: 12, height: 120),
            metadataState: .medium
        )

        XCTAssertEqual(offset.width, 0, accuracy: 0.001)
        XCTAssertEqual(offset.height, 21.6, accuracy: 0.001)
    }

    func testCollapsedMetadataKeepsFullPhotoDragOffset() {
        let offset = MediaViewerPresentation.photoDragOffset(
            translation: CGSize(width: 18, height: 120),
            metadataState: .collapsed
        )

        XCTAssertEqual(offset.width, 18, accuracy: 0.001)
        XCTAssertEqual(offset.height, 120, accuracy: 0.001)
    }

    func testDragProgressNeverMovesAtmosphereLayer() {
        XCTAssertEqual(
            MediaViewerPresentation.atmosphereOffset(for: CGSize(width: 0, height: 180)),
            .zero
        )
    }

    func testPhotoCanvasHeightKeepsCollapsedViewerOffFullScreen() {
        XCTAssertEqual(
            MediaViewerPresentation.photoCanvasHeight(
                viewportHeight: 956,
                safeTopInset: 59,
                safeBottomInset: 34,
                metadataHeight: nil
            ),
            719,
            accuracy: 0.5
        )
    }

    func testPhotoCanvasHeightShrinksWhenMetadataIsVisible() {
        XCTAssertEqual(
            MediaViewerPresentation.photoCanvasHeight(
                viewportHeight: 956,
                safeTopInset: 59,
                safeBottomInset: 34,
                metadataHeight: 446
            ),
            361,
            accuracy: 0.5
        )
    }

    func testPhotoViewportInsetsReserveChromeAndMetadataSpace() {
        let insets = MediaViewerPresentation.photoViewportInsets(
            safeTopInset: 59,
            safeBottomInset: 34,
            metadataHeight: 446
        )

        XCTAssertEqual(insets.top, 131, accuracy: 0.5)
        XCTAssertEqual(insets.bottom, 464, accuracy: 0.5)
    }

    func testPhotoDisplayRectUsesInsetCanvasInsteadOfFullScreen() {
        let rect = MediaViewerPresentation.photoDisplayRect(
            imageSize: CGSize(width: 724, height: 1086),
            viewportSize: CGSize(width: 430, height: 956),
            safeTopInset: 59,
            safeBottomInset: 34,
            metadataHeight: nil
        )

        XCTAssertEqual(rect.width, 430, accuracy: 0.5)
        XCTAssertEqual(rect.height, 645, accuracy: 0.5)
        XCTAssertEqual(rect.midY, 490.5, accuracy: 0.5)
    }

    func testPhotoDisplayRectBottomAnchorsAboveViewerCardWhenMetadataVisible() {
        let rect = MediaViewerPresentation.photoDisplayRect(
            imageSize: CGSize(width: 1086, height: 724),
            viewportSize: CGSize(width: 430, height: 956),
            safeTopInset: 59,
            safeBottomInset: 34,
            metadataHeight: MediaMetadataPresentation.viewerCardHeight(for: 956)
        )

        XCTAssertEqual(rect.width, 430, accuracy: 0.5)
        XCTAssertEqual(rect.height, 286.7, accuracy: 0.5)
        XCTAssertEqual(rect.maxY, 670, accuracy: 0.5)
    }
}
