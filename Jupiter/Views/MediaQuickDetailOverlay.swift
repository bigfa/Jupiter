import SwiftUI
import UIKit

struct MediaQuickPagerOverlay: View {
    let items: [MediaItem]
    @Binding var selection: Int
    @Binding var heroId: String?
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    @Binding var showHeroOverlay: Bool
    let imageCache: [String: UIImage]
    let onCacheImage: (String, UIImage) -> Void
    let isActive: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            TabView(selection: $selection) {
                ForEach(items.indices, id: \.self) { index in
                    let isHero = heroId == items[index].id
                    MediaQuickDetailPage(
                        item: items[index],
                        cachedImage: imageCache[items[index].id],
                        namespace: namespace,
                        isHero: false,
                        hideImage: showHeroOverlay && isHero,
                        onImageLoaded: {
                            if isHero && isActive {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    if showHeroOverlay && heroId == items[index].id && isActive {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showHeroOverlay = false
                                        }
                                    }
                                }
                            }
                        },
                        onCacheImage: { image in
                            onCacheImage(items[index].id, image)
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                if heroId == nil, items.indices.contains(selection) {
                    heroId = items[selection].id
                }
            }
            .onChange(of: selection) { _, newIndex in
                if items.indices.contains(newIndex) {
                    heroId = items[newIndex].id
                }
            }

            if showHeroOverlay, let heroItem = currentHeroItem {
                MediaQuickHeroImage(
                    item: heroItem,
                    cachedImage: imageCache[heroItem.id],
                    namespace: namespace
                )
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(16)
            }
        }
    }

    private var currentHeroItem: MediaItem? {
        guard let heroId else { return nil }
        return items.first(where: { $0.id == heroId })
    }
}

struct MediaQuickDetailPage: View {
    let item: MediaItem
    let cachedImage: UIImage?
    let namespace: Namespace.ID
    let isHero: Bool
    let hideImage: Bool
    let onImageLoaded: (() -> Void)?
    let onCacheImage: ((UIImage) -> Void)?

    @State private var showZoom = false
    @State private var isSheetExpanded = false

    private var bestURL: URL? {
        let candidate = item.urlLarge ?? item.urlMedium ?? item.urlThumb ?? item.url
        return URL(string: candidate)
    }

    private var resolvedURL: URL? {
        guard let bestURL else { return nil }
        if bestURL.scheme != nil {
            return bestURL
        }
        return URL(string: bestURL.absoluteString, relativeTo: AppConfig.baseURL)?.absoluteURL
    }

    var body: some View {
        GeometryReader { proxy in
            let collapsedHeight: CGFloat = 72
            let expandedHeight: CGFloat = min(360, proxy.size.height * 0.45)
            let layout = imageLayout(in: proxy.size, collapsedHeight: collapsedHeight, cachedSize: cachedImage?.size)

            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Spacer(minLength: layout.topPadding)
                        heroImage(
                            containerWidth: proxy.size.width,
                            imageSize: CGSize(width: layout.imageWidth, height: layout.imageHeight)
                        )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showZoom = true
                            }
                        Spacer(minLength: layout.topPadding)
                    }
                    .frame(height: layout.availableHeight)
                    Spacer(minLength: collapsedHeight + 16)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                MediaMetadataSheet(
                    item: item,
                    isExpanded: $isSheetExpanded,
                    collapsedHeight: collapsedHeight,
                    expandedHeight: expandedHeight
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showZoom) {
            ZoomViewer(url: resolvedURL)
        }
        .onAppear {
            if cachedImage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onImageLoaded?()
                }
            }
        }
    }

    private func imageLayout(in size: CGSize, collapsedHeight: CGFloat, cachedSize: CGSize?) -> (availableHeight: CGFloat, imageHeight: CGFloat, topPadding: CGFloat, imageWidth: CGFloat) {
        let bottomPadding: CGFloat = 16
        let availableHeight = max(size.height - collapsedHeight - bottomPadding, 200)
        let width = CGFloat(item.width ?? 0)
        let height = CGFloat(item.height ?? 0)
        let resolvedWidth = width > 0 ? width : (cachedSize?.width ?? 0)
        let resolvedHeight = height > 0 ? height : (cachedSize?.height ?? 0)
        guard resolvedWidth > 0, resolvedHeight > 0 else {
            return (availableHeight, availableHeight, 0, size.width)
        }
        let aspect = resolvedWidth / resolvedHeight
        let naturalHeight = size.width / aspect
        let imageHeight = min(availableHeight, naturalHeight)
        let topPadding = max((availableHeight - imageHeight) / 2, 0)
        let imageWidth = min(size.width, aspect * imageHeight)
        return (availableHeight, imageHeight, topPadding, imageWidth)
    }

    @ViewBuilder
    private func heroImage(containerWidth: CGFloat, imageSize: CGSize) -> some View {
        let imageView = Group {
            if let cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFit()
            } else {
                RemoteImage(
                    url: resolvedURL ?? bestURL,
                    contentMode: .fit,
                    fadeDuration: 0,
                    onLoad: {
                        onImageLoaded?()
                    },
                    onImage: { image in
                        onCacheImage?(image)
                    },
                    showsProgress: false,
                    disableAnimations: true
                )
            }
        }
        .frame(width: imageSize.width, height: imageSize.height)
        .clipped()
        .opacity(hideImage ? 0 : 1)

        if isHero {
            imageView
                .matchedGeometryEffect(id: item.id, in: namespace, isSource: false)
                .frame(width: containerWidth, height: imageSize.height, alignment: .center)
        } else {
            imageView
                .frame(width: containerWidth, height: imageSize.height, alignment: .center)
        }
    }
}

struct MediaQuickHeroImage: View {
    let item: MediaItem
    let cachedImage: UIImage?
    let namespace: Namespace.ID

    private var bestURL: URL? {
        let candidate = item.urlLarge ?? item.urlMedium ?? item.urlThumb ?? item.url
        return URL(string: candidate)
    }

    private var resolvedURL: URL? {
        guard let bestURL else { return nil }
        if bestURL.scheme != nil {
            return bestURL
        }
        return URL(string: bestURL.absoluteString, relativeTo: AppConfig.baseURL)?.absoluteURL
    }

    var body: some View {
        GeometryReader { proxy in
            let collapsedHeight: CGFloat = 72
            let layout = imageLayout(in: proxy.size, collapsedHeight: collapsedHeight, cachedSize: cachedImage?.size)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Spacer(minLength: layout.topPadding)
                    heroImage(size: CGSize(width: layout.imageWidth, height: layout.imageHeight))
                        .matchedGeometryEffect(id: item.id, in: namespace, isSource: false)
                        .frame(width: proxy.size.width, height: layout.imageHeight, alignment: .center)
                    Spacer(minLength: layout.topPadding)
                }
                .frame(height: layout.availableHeight)
                Spacer(minLength: collapsedHeight + 16)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea()
    }

    private func imageLayout(in size: CGSize, collapsedHeight: CGFloat, cachedSize: CGSize?) -> (availableHeight: CGFloat, imageHeight: CGFloat, topPadding: CGFloat, imageWidth: CGFloat) {
        let bottomPadding: CGFloat = 16
        let availableHeight = max(size.height - collapsedHeight - bottomPadding, 200)
        let width = CGFloat(item.width ?? 0)
        let height = CGFloat(item.height ?? 0)
        let resolvedWidth = width > 0 ? width : (cachedSize?.width ?? 0)
        let resolvedHeight = height > 0 ? height : (cachedSize?.height ?? 0)
        guard resolvedWidth > 0, resolvedHeight > 0 else {
            return (availableHeight, availableHeight, 0, size.width)
        }
        let aspect = resolvedWidth / resolvedHeight
        let naturalHeight = size.width / aspect
        let imageHeight = min(availableHeight, naturalHeight)
        let topPadding = max((availableHeight - imageHeight) / 2, 0)
        let imageWidth = min(size.width, aspect * imageHeight)
        return (availableHeight, imageHeight, topPadding, imageWidth)
    }

    @ViewBuilder
    private func heroImage(size: CGSize) -> some View {
        if let cachedImage {
            Image(uiImage: cachedImage)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            RemoteImage(
                url: resolvedURL ?? bestURL,
                contentMode: .fit,
                fadeDuration: 0,
                showsProgress: false,
                disableAnimations: true
            )
            .frame(width: size.width, height: size.height)
            .clipped()
        }
    }
}

struct MediaMetadataSheet: View {
    let item: MediaItem
    @Binding var isExpanded: Bool
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat

    @GestureState private var dragTranslation: CGFloat = 0

    var body: some View {
        let baseHeight = isExpanded ? expandedHeight : collapsedHeight
        let stableTranslation = abs(dragTranslation) < 1 ? 0 : dragTranslation.rounded()
        let proposedHeight = baseHeight - stableTranslation
        let currentHeight = min(max(proposedHeight, collapsedHeight), expandedHeight)

        VStack(spacing: 10) {
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color.black.opacity(0.18))
                    .frame(width: 36, height: 4)
                    .padding(.top, 2)

                HStack {
                    Text("Metadata")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(sheetDragGesture)

            if isExpanded {
                ScrollView(showsIndicators: false) {
                    MediaItemInfoView(item: item)
                        .padding(.top, 4)
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .frame(height: currentHeight, alignment: .top)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
        .onTapGesture {
            if !isExpanded {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    isExpanded = true
                }
            }
        }
    }

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($dragTranslation) { value, state, _ in
                let delta = value.translation.height
                state = abs(delta) < 2 ? 0 : delta
            }
            .onEnded { value in
                if value.translation.height < -20 {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        isExpanded = true
                    }
                } else if value.translation.height > 20 {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        isExpanded = false
                    }
                }
            }
    }
}

struct MediaItemInfoView: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if infoCards.isEmpty {
                Text("No EXIF data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                    ForEach(Array(cardRows.enumerated()), id: \.offset) { _, row in
                        GridRow(alignment: .top) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, card in
                                infoCard(field: card.field, value: card.value)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                            if row.count == 1 {
                                Color.clear
                                    .gridCellUnsizedAxes([.vertical])
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var infoCards: [(field: MetadataInfoField, value: String)] {
        var cards: [(field: MetadataInfoField, value: String)] = []
        addCard(&cards, field: .camera, value: item.cameraModel)
        addCard(&cards, field: .lens, value: item.lensModel)
        addCard(&cards, field: .aperture, value: item.aperture)
        addCard(&cards, field: .shutter, value: item.shutterSpeed)
        addCard(&cards, field: .iso, value: item.iso)
        addCard(&cards, field: .focalLength, value: item.focalLength)
        addCard(&cards, field: .format, value: item.mimeType)
        addCard(&cards, field: .shootTime, value: formatDate(item.datetimeOriginal))
        addCard(&cards, field: .gps, value: coordinateText)
        addCard(&cards, field: .location, value: item.locationName)
        if let tags = item.tags, !tags.isEmpty {
            addCard(&cards, field: .tags, value: tags.joined(separator: ", "))
        }
        if let categories = item.categories, !categories.isEmpty {
            addCard(&cards, field: .categories, value: categories.map { $0.name }.joined(separator: ", "))
        }
        return cards
    }

    private var cardRows: [[(field: MetadataInfoField, value: String)]] {
        stride(from: 0, to: infoCards.count, by: 2).map { start in
            Array(infoCards[start..<min(start + 2, infoCards.count)])
        }
    }

    private func addCard(_ cards: inout [(field: MetadataInfoField, value: String)], field: MetadataInfoField, value: String?) {
        guard let value else { return }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        cards.append((field: field, value: trimmed))
    }

    private func infoCard(field: MetadataInfoField, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            MetadataLineIcon(field: field)
                .frame(width: 36, height: 36)
                .accessibilityLabel(field.accessibilityTitle)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private enum MetadataInfoField: Hashable {
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

    private struct MetadataLineIcon: View {
        let field: MetadataInfoField

        @ViewBuilder
        var body: some View {
            Group {
                if field == .iso {
                    isoBadgeIcon
                } else if field == .focalLength {
                    focalLengthBadgeIcon
                } else {
                    GeometryReader { proxy in
                        iconPath(in: proxy.frame(in: .local))
                            .stroke(
                                Color.black.opacity(0.58),
                                style: StrokeStyle(
                                    lineWidth: 1.3,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)
        }

        private var focalLengthBadgeIcon: some View {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                let strokeColor = Color.black.opacity(0.58)

                ZStack {
                    Text("mm")
                        .font(.system(size: side * 0.26, weight: .semibold, design: .rounded))
                        .foregroundStyle(strokeColor)
                        .offset(y: -side * 0.16)

                    Path { path in
                        let y = side * 0.70
                        let left = side * 0.16
                        let right = side * 0.84
                        let arrow = side * 0.10

                        path.move(to: CGPoint(x: left, y: y))
                        path.addLine(to: CGPoint(x: right, y: y))

                        path.move(to: CGPoint(x: left + arrow, y: y - arrow * 0.7))
                        path.addLine(to: CGPoint(x: left, y: y))
                        path.addLine(to: CGPoint(x: left + arrow, y: y + arrow * 0.7))

                        path.move(to: CGPoint(x: right - arrow, y: y - arrow * 0.7))
                        path.addLine(to: CGPoint(x: right, y: y))
                        path.addLine(to: CGPoint(x: right - arrow, y: y + arrow * 0.7))
                    }
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }

        private var isoBadgeIcon: some View {
            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                let inset = side * 0.08
                let strokeColor = Color.black.opacity(0.58)

                ZStack {
                    RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1.3)
                        .padding(inset)

                    Text("ISO")
                        .font(.system(size: side * 0.34, weight: .semibold, design: .rounded))
                        .foregroundStyle(strokeColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }

        private func iconPath(in rect: CGRect) -> Path {
            let side = min(rect.width, rect.height)
            let minX = rect.midX - side / 2
            let minY = rect.midY - side / 2

            func x(_ value: CGFloat) -> CGFloat { minX + value / 24 * side }
            func y(_ value: CGFloat) -> CGFloat { minY + value / 24 * side }
            func point(_ px: CGFloat, _ py: CGFloat) -> CGPoint { CGPoint(x: x(px), y: y(py)) }
            func box(_ px: CGFloat, _ py: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x(px), y: y(py), width: w / 24 * side, height: h / 24 * side)
            }

            var path = Path()

            switch field {
            case .camera:
                path.addPath(Path(roundedRect: box(2, 8, 20, 12), cornerRadius: side * 2.5 / 24))
                path.move(to: point(8, 8))
                path.addLine(to: point(9.4, 6))
                path.addLine(to: point(14.6, 6))
                path.addLine(to: point(16, 8))
                path.addEllipse(in: box(8.5, 10.5, 7, 7))
                path.addEllipse(in: box(17.1, 10.1, 1.8, 1.8))

            case .lens:
                path.addEllipse(in: box(3.5, 3.5, 17, 17))
                path.addEllipse(in: box(7, 7, 10, 10))
                path.addEllipse(in: box(10, 10, 4, 4))

            case .aperture:
                path.addEllipse(in: box(3.5, 3.5, 17, 17))
                path.move(to: point(12, 12)); path.addLine(to: point(8.3, 5.8))
                path.move(to: point(12, 12)); path.addLine(to: point(16.5, 6.6))
                path.move(to: point(12, 12)); path.addLine(to: point(19, 10.9))
                path.move(to: point(12, 12)); path.addLine(to: point(16.8, 17.1))
                path.move(to: point(12, 12)); path.addLine(to: point(10.2, 19))
                path.move(to: point(12, 12)); path.addLine(to: point(5.4, 15.4))
                path.addEllipse(in: box(10, 10, 4, 4))

            case .shutter:
                path.addEllipse(in: box(3.5, 3.5, 17, 17))
                path.move(to: point(12, 8))
                path.addLine(to: point(12, 12))
                path.addLine(to: point(15, 14))
                path.move(to: point(7, 4.5))
                path.addLine(to: point(5, 6.5))

            case .iso:
                break

            case .focalLength:
                break

            case .format:
                path.move(to: point(7, 3))
                path.addLine(to: point(14, 3))
                path.addLine(to: point(18, 7))
                path.addLine(to: point(18, 21))
                path.addLine(to: point(7, 21))
                path.addLine(to: point(7, 3))
                path.move(to: point(14, 3))
                path.addLine(to: point(14, 8))
                path.addLine(to: point(18, 8))
                path.move(to: point(9, 13)); path.addLine(to: point(15, 13))
                path.move(to: point(9, 17)); path.addLine(to: point(15, 17))

            case .shootTime:
                path.addPath(Path(roundedRect: box(4, 5, 16, 15), cornerRadius: side * 2 / 24))
                path.move(to: point(8, 3)); path.addLine(to: point(8, 7))
                path.move(to: point(16, 3)); path.addLine(to: point(16, 7))
                path.move(to: point(4, 9)); path.addLine(to: point(20, 9))
                path.addEllipse(in: box(9.2, 11.2, 5.6, 5.6))
                path.move(to: point(12, 12.8)); path.addLine(to: point(12, 14.4)); path.addLine(to: point(13.2, 15.2))

            case .gps:
                path.addEllipse(in: box(6, 6, 12, 12))
                path.addEllipse(in: box(10.5, 10.5, 3, 3))
                path.move(to: point(12, 2)); path.addLine(to: point(12, 6))
                path.move(to: point(12, 18)); path.addLine(to: point(12, 22))
                path.move(to: point(2, 12)); path.addLine(to: point(6, 12))
                path.move(to: point(18, 12)); path.addLine(to: point(22, 12))

            case .location:
                path.move(to: point(12, 21))
                path.addQuadCurve(to: point(6, 11), control: point(6, 17))
                path.addQuadCurve(to: point(12, 5), control: point(6, 6))
                path.addQuadCurve(to: point(18, 11), control: point(18, 6))
                path.addQuadCurve(to: point(12, 21), control: point(18, 17))
                path.addEllipse(in: box(9.8, 8.8, 4.4, 4.4))

            case .tags:
                path.move(to: point(3, 11))
                path.addLine(to: point(11, 3))
                path.addLine(to: point(18, 3))
                path.addLine(to: point(18, 10))
                path.addLine(to: point(10, 18))
                path.addLine(to: point(3, 11))
                path.addEllipse(in: box(13.5, 5.5, 2, 2))

            case .categories:
                path.addPath(Path(roundedRect: box(4, 4, 7, 7), cornerRadius: side * 1.5 / 24))
                path.addPath(Path(roundedRect: box(13, 4, 7, 7), cornerRadius: side * 1.5 / 24))
                path.addPath(Path(roundedRect: box(4, 13, 7, 7), cornerRadius: side * 1.5 / 24))
                path.addPath(Path(roundedRect: box(13, 13, 7, 7), cornerRadius: side * 1.5 / 24))
            }

            return path
        }
    }

    private var coordinateText: String? {
        guard let lat = item.gpsLat, let lon = item.gpsLon else { return nil }
        return String(format: "%.5f, %.5f", lat, lon)
    }

    private func formatDate(_ value: String?) -> String? {
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
