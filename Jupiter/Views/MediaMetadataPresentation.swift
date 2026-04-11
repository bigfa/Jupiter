import Foundation

enum MediaMetadataContentState: Equatable {
    case loadingSkeleton
    case content
    case empty
}

struct MediaMetadataCardItem: Equatable, Identifiable {
    let field: MediaMetadataField
    let value: String

    var id: String { "\(field.rawValue)-\(value)" }
}

enum MediaMetadataField: String, Equatable {
    case camera
    case lens
    case aperture
    case shutter
    case iso
    case focalLength
    case format
    case shootTime
    case gps
    case location
    case tags
    case categories

    var accessibilityTitle: String {
        switch self {
        case .camera: return String(localized: "Camera")
        case .lens: return String(localized: "Lens")
        case .aperture: return String(localized: "Aperture")
        case .shutter: return String(localized: "Shutter")
        case .iso: return String(localized: "ISO")
        case .focalLength: return String(localized: "Focal length")
        case .format: return String(localized: "Format")
        case .shootTime: return String(localized: "Shoot time")
        case .gps: return String(localized: "GPS")
        case .location: return String(localized: "Location")
        case .tags: return String(localized: "Tags")
        case .categories: return String(localized: "Categories")
        }
    }
}

enum MediaMetadataPresentation {
    private static let compactHeightRatio: CGFloat = 0.28
    private static let minimumCardHeight: CGFloat = 220
    private static let maximumCardHeight: CGFloat = 320
    private static let gridColumns = 2
    private static let gridRowSpacing: CGFloat = 10
    private static let compactGridItemHeight: CGFloat = 110
    private static let skeletonPlaceholderCount = 6
    private static let chromeContentPadding: CGFloat = 62
    private static let expandedHeightRatio: CGFloat = 0.52
    private static let expandedMaximumCardHeight: CGFloat = 520

    static func cardHeight(for viewportHeight: CGFloat) -> CGFloat {
        min(max(viewportHeight * compactHeightRatio, minimumCardHeight), maximumCardHeight)
    }

    static func viewerCardHeight(for viewportHeight: CGFloat) -> CGFloat {
        cardHeight(for: viewportHeight)
    }

    static func viewerCardHeight(
        for viewportHeight: CGFloat,
        item: MediaItem,
        isDetailLoading: Bool,
        bottomSafeInset: CGFloat
    ) -> CGFloat {
        let contentHeight = gridContentHeight(
            for: cardCount(for: item, isDetailLoading: isDetailLoading)
        )
        return fittedCardHeight(
            viewportHeight: viewportHeight,
            contentHeight: contentHeight,
            bottomSafeInset: bottomSafeInset
        )
    }

    static func gridRowCount(for cardCount: Int) -> Int {
        guard cardCount > 0 else { return 0 }
        return Int(ceil(CGFloat(cardCount) / CGFloat(gridColumns)))
    }

    static func gridContentHeight(for cardCount: Int) -> CGFloat {
        let rows = gridRowCount(for: cardCount)
        guard rows > 0 else { return compactGridItemHeight }
        return CGFloat(rows) * compactGridItemHeight + CGFloat(max(0, rows - 1)) * gridRowSpacing
    }

    static func rows(for cards: [MediaMetadataCardItem]) -> [[MediaMetadataCardItem]] {
        stride(from: 0, to: cards.count, by: gridColumns).map { start in
            Array(cards[start..<min(start + gridColumns, cards.count)])
        }
    }

    static func gridItemWidth(containerWidth: CGFloat) -> CGFloat {
        let totalSpacing = CGFloat(max(0, gridColumns - 1)) * gridRowSpacing
        let availableWidth = max(containerWidth - totalSpacing, 0)
        return availableWidth / CGFloat(gridColumns)
    }

    static func fittedCardHeight(
        viewportHeight: CGFloat,
        contentHeight: CGFloat,
        bottomSafeInset: CGFloat
    ) -> CGFloat {
        let preferredHeight = contentHeight + chromeContentPadding + bottomSafeInset
        let minimumVisibleHeight = compactGridItemHeight + chromeContentPadding + bottomSafeInset
        let expandedLimit = min(viewportHeight * expandedHeightRatio, expandedMaximumCardHeight)
        return min(
            expandedLimit,
            max(preferredHeight, minimumVisibleHeight)
        )
    }

    static func contentState(item: MediaItem, isDetailLoading: Bool) -> MediaMetadataContentState {
        if hasPresentableMetadata(item) {
            return .content
        }

        if isDetailLoading {
            return .loadingSkeleton
        }

        return .empty
    }

    static func cardCount(for item: MediaItem, isDetailLoading: Bool) -> Int {
        switch contentState(item: item, isDetailLoading: isDetailLoading) {
        case .loadingSkeleton:
            return skeletonPlaceholderCount
        case .empty:
            return 1
        case .content:
            return cards(for: item).count
        }
    }

    static func cards(for item: MediaItem) -> [MediaMetadataCardItem] {
        var cards: [MediaMetadataCardItem] = []
        addCard(&cards, field: .camera, value: item.cameraModel)
        addCard(&cards, field: .lens, value: item.lensModel)
        addCard(&cards, field: .aperture, value: item.aperture)
        addCard(&cards, field: .shutter, value: item.shutterSpeed)
        addCard(&cards, field: .iso, value: item.iso)
        addCard(&cards, field: .focalLength, value: item.focalLength)
        addCard(&cards, field: .format, value: item.mimeType)
        addCard(&cards, field: .shootTime, value: formatDate(item.datetimeOriginal))
        addCard(&cards, field: .gps, value: coordinateText(for: item))
        addCard(&cards, field: .location, value: item.locationName)

        if let tags = item.tags, !tags.isEmpty {
            addCard(&cards, field: .tags, value: tags.joined(separator: ", "))
        }

        if let categories = item.categories, !categories.isEmpty {
            addCard(&cards, field: .categories, value: categories.map(\.name).joined(separator: ", "))
        }

        return cards
    }

    static func hasPresentableMetadata(_ item: MediaItem) -> Bool {
        !cards(for: item).isEmpty
    }

    private static func addCard(_ cards: inout [MediaMetadataCardItem], field: MediaMetadataField, value: String?) {
        guard let value else { return }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        cards.append(MediaMetadataCardItem(field: field, value: trimmed))
    }

    private static func coordinateText(for item: MediaItem) -> String? {
        guard let lat = item.gpsLat, let lon = item.gpsLon else { return nil }
        return String(format: "%.5f, %.5f", lat, lon)
    }

    private static func formatDate(_ value: String?) -> String? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return formattedDate(date)
        }

        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        if let date = isoFallback.date(from: value) {
            return formattedDate(date)
        }

        let exif = DateFormatter()
        exif.locale = Locale(identifier: "en_US_POSIX")
        exif.timeZone = TimeZone.current
        exif.dateFormat = "yyyy:MM:dd HH:mm:ss"
        if let date = exif.date(from: value) {
            return formattedDate(date)
        }

        return value
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
