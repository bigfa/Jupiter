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
            if let filename = item.filename, !filename.isEmpty {
                Text(filename)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }

            if infoCards.isEmpty {
                Text("暂无EXIF信息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                    ForEach(Array(infoCards.enumerated()), id: \.offset) { _, card in
                        infoCard(title: card.label, value: card.value)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 120, maximum: .infinity), spacing: 10, alignment: .top),
            GridItem(.flexible(minimum: 120, maximum: .infinity), spacing: 10, alignment: .top)
        ]
    }

    private var infoCards: [(label: String, value: String)] {
        var cards: [(label: String, value: String)] = []
        addCard(&cards, label: "相机", value: [item.cameraMake, item.cameraModel].compactMap { $0 }.joined(separator: " "))
        addCard(&cards, label: "镜头", value: item.lensModel)
        addCard(&cards, label: "光圈", value: item.aperture)
        addCard(&cards, label: "快门", value: item.shutterSpeed)
        addCard(&cards, label: "ISO", value: item.iso)
        addCard(&cards, label: "焦距", value: item.focalLength)
        addCard(&cards, label: "尺寸", value: dimensionsText)
        addCard(&cards, label: "长宽比", value: aspectRatioText)
        addCard(&cards, label: "大小", value: fileSizeText)
        addCard(&cards, label: "格式", value: item.mimeType)
        addCard(&cards, label: "拍摄时间", value: formatDate(item.datetimeOriginal))
        addCard(&cards, label: "上传时间", value: formatDate(item.createdAt))
        addCard(&cards, label: "经纬度", value: coordinateText)
        addCard(&cards, label: "位置", value: item.locationName)
        if let tags = item.tags, !tags.isEmpty {
            addCard(&cards, label: "标签", value: tags.joined(separator: ", "))
        }
        if let categories = item.categories, !categories.isEmpty {
            addCard(&cards, label: "分类", value: categories.map { $0.name }.joined(separator: ", "))
        }
        return cards
    }

    private func addCard(_ cards: inout [(label: String, value: String)], label: String, value: String?) {
        guard let value else { return }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        cards.append((label: label, value: trimmed))
    }

    private func infoCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var dimensionsText: String? {
        guard let w = item.width, let h = item.height else { return nil }
        return "\(w) × \(h)"
    }

    private var aspectRatioText: String? {
        guard let w = item.width, let h = item.height, h != 0 else { return nil }
        let ratio = Double(w) / Double(h)
        return String(format: "%.2f", ratio)
    }

    private var fileSizeText: String? {
        guard let size = item.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
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
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
