import CoreGraphics
import SwiftUI

enum ViewerMetadataState {
    case collapsed
    case medium
    case expanded
}

enum ViewerPageDirection {
    case previous
    case next
}

struct ViewerPageOffsets {
    let outbound: CGFloat
    let inbound: CGFloat
}

struct ViewerPhotoViewportInsets {
    let top: CGFloat
    let bottom: CGFloat
}

enum MediaViewerPresentation {
    private static let closeThreshold: CGFloat = 100
    private static let predictedThreshold: CGFloat = 300
    private static let metadataCollapseThreshold: CGFloat = 72
    private static let minimumZoomForDismiss: CGFloat = 1.01
    private static let fallbackChromeTopPadding: CGFloat = 56
    private static let chromeTopPaddingInset: CGFloat = 24
    private static let chromeButtonInset: CGFloat = 12
    private static let photoTopClearance: CGFloat = 60
    private static let photoCollapsedBottomReserve: CGFloat = 106
    private static let photoMetadataSpacing: CGFloat = 18
    private static let minimumPhotoCanvasHeight: CGFloat = 240

    static func startIndex(items: [MediaItem], startId: String) -> Int {
        items.firstIndex(where: { $0.id == startId }) ?? 0
    }

    static func neighboringIndex(
        currentIndex: Int,
        direction: ViewerPageDirection,
        itemCount: Int
    ) -> Int? {
        guard itemCount > 0 else { return nil }
        let candidate = direction == .next ? currentIndex + 1 : currentIndex - 1
        guard candidate >= 0, candidate < itemCount else { return nil }
        return candidate
    }

    static func shouldRequestMore(afterSelecting index: Int, itemCount: Int) -> Bool {
        guard itemCount > 0 else { return false }
        return index >= itemCount - 2
    }

    static func shouldActivatePage(pageIndex: Int, selectedIndex: Int) -> Bool {
        pageIndex == selectedIndex
    }

    static func aspectFitRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        let containerRect = CGRect(origin: .zero, size: containerSize)
        guard imageSize.width > 0, imageSize.height > 0 else {
            return containerRect
        }

        let scale = min(
            containerSize.width / imageSize.width,
            containerSize.height / imageSize.height
        )
        let fittedSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        let origin = CGPoint(
            x: containerRect.midX - fittedSize.width / 2,
            y: containerRect.midY - fittedSize.height / 2
        )
        return CGRect(origin: origin, size: fittedSize)
    }

    static func shouldDismissPhoto(
        translationY: CGFloat,
        predictedTranslationY: CGFloat,
        zoomScale: CGFloat,
        metadataState: ViewerMetadataState
    ) -> Bool {
        guard zoomScale <= minimumZoomForDismiss else { return false }
        guard metadataState == .collapsed else { return false }

        let isDownward = translationY > 0 || predictedTranslationY > 0
        guard isDownward else { return false }

        return translationY > closeThreshold || predictedTranslationY > predictedThreshold
    }

    static func chromeTopPadding(safeTopInset: CGFloat) -> CGFloat {
        safeTopInset > 0 ? safeTopInset + chromeTopPaddingInset : fallbackChromeTopPadding
    }

    static func chromeButtonTopInset(safeTopInset: CGFloat) -> CGFloat {
        safeTopInset > 0 ? safeTopInset + chromeButtonInset : fallbackChromeTopPadding
    }

    static func photoTopInset(safeTopInset: CGFloat) -> CGFloat {
        chromeButtonTopInset(safeTopInset: safeTopInset) + photoTopClearance
    }

    static func photoBottomInset(
        safeBottomInset: CGFloat,
        metadataHeight: CGFloat?
    ) -> CGFloat {
        if let metadataHeight {
            return metadataHeight + photoMetadataSpacing
        }
        return max(photoCollapsedBottomReserve, safeBottomInset + 72)
    }

    static func photoViewportInsets(
        safeTopInset: CGFloat,
        safeBottomInset: CGFloat,
        metadataHeight: CGFloat?
    ) -> ViewerPhotoViewportInsets {
        ViewerPhotoViewportInsets(
            top: photoTopInset(safeTopInset: safeTopInset),
            bottom: photoBottomInset(
                safeBottomInset: safeBottomInset,
                metadataHeight: metadataHeight
            )
        )
    }

    static func photoCanvasHeight(
        viewportHeight: CGFloat,
        safeTopInset: CGFloat,
        safeBottomInset: CGFloat,
        metadataHeight: CGFloat?
    ) -> CGFloat {
        let insets = photoViewportInsets(
            safeTopInset: safeTopInset,
            safeBottomInset: safeBottomInset,
            metadataHeight: metadataHeight
        )
        let availableHeight = viewportHeight
            - insets.top
            - insets.bottom
        return max(minimumPhotoCanvasHeight, availableHeight)
    }

    static func photoCanvasRect(
        viewportSize: CGSize,
        safeTopInset: CGFloat,
        safeBottomInset: CGFloat,
        metadataHeight: CGFloat?
    ) -> CGRect {
        let insets = photoViewportInsets(
            safeTopInset: safeTopInset,
            safeBottomInset: safeBottomInset,
            metadataHeight: metadataHeight
        )
        return CGRect(
            x: 0,
            y: insets.top,
            width: viewportSize.width,
            height: photoCanvasHeight(
                viewportHeight: viewportSize.height,
                safeTopInset: safeTopInset,
                safeBottomInset: safeBottomInset,
                metadataHeight: metadataHeight
            )
        )
    }

    static func photoDisplayRect(
        imageSize: CGSize,
        viewportSize: CGSize,
        safeTopInset: CGFloat,
        safeBottomInset: CGFloat,
        metadataHeight: CGFloat?
    ) -> CGRect {
        let canvasRect = photoCanvasRect(
            viewportSize: viewportSize,
            safeTopInset: safeTopInset,
            safeBottomInset: safeBottomInset,
            metadataHeight: metadataHeight
        )
        let fittedRect = aspectFitRect(imageSize: imageSize, containerSize: canvasRect.size)
        let originY: CGFloat
        if metadataHeight != nil {
            originY = canvasRect.maxY - fittedRect.height
        } else {
            originY = canvasRect.minY + fittedRect.minY
        }
        return CGRect(
            x: canvasRect.minX + fittedRect.minX,
            y: originY,
            width: fittedRect.width,
            height: fittedRect.height
        )
    }

    // Returns the hero image's resting frame against the full visual canvas, not a safe-area-cropped layout.
    static func heroRestingFrame(
        imageSize: CGSize,
        viewportSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> CGRect {
        let fullCanvasSize = CGSize(
            width: viewportSize.width,
            height: viewportSize.height + safeAreaInsets.top + safeAreaInsets.bottom
        )
        return aspectFitRect(imageSize: imageSize, containerSize: fullCanvasSize)
    }

    static func heroRestingPosition(
        imageSize: CGSize,
        viewportSize: CGSize,
        safeAreaInsets: EdgeInsets
    ) -> CGPoint {
        let frame = heroRestingFrame(
            imageSize: imageSize,
            viewportSize: viewportSize,
            safeAreaInsets: safeAreaInsets
        )
        return CGPoint(
            x: frame.midX,
            y: frame.midY - safeAreaInsets.top
        )
    }

    static func pageOffsets(direction: ViewerPageDirection, width: CGFloat) -> ViewerPageOffsets {
        let resolvedWidth = max(1, width)
        let outbound = direction == .next ? -resolvedWidth : resolvedWidth
        return ViewerPageOffsets(
            outbound: outbound,
            inbound: -outbound
        )
    }

    static func photoDragShouldCollapseMetadata(
        translationY: CGFloat,
        metadataState: ViewerMetadataState
    ) -> Bool {
        guard metadataState != .collapsed else { return false }
        return translationY > metadataCollapseThreshold
    }

    static func photoDragOffset(
        translation: CGSize,
        metadataState: ViewerMetadataState
    ) -> CGSize {
        guard metadataState != .collapsed else { return translation }
        return CGSize(
            width: 0,
            height: max(translation.height, 0) * 0.18
        )
    }

    static func atmosphereOffset(for dragOffset: CGSize) -> CGSize {
        .zero
    }
}
