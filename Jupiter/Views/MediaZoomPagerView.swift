import SwiftUI
import UIKit
import Photos

struct MediaZoomPagerView: View {
    let items: [MediaItem]
    let namespace: Namespace.ID
    @State private var selection: Int
    let onReachEnd: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isVerticalDragging: Bool = false
    @State private var showMetadata = false
    @State private var pageSlideOffset: CGFloat = 0
    @State private var isPageAnimating = false

    init(items: [MediaItem], startId: String, namespace: Namespace.ID, onReachEnd: (() -> Void)? = nil) {
        self.items = items
        self.namespace = namespace
        self.onReachEnd = onReachEnd
        let startIndex = items.firstIndex(where: { $0.id == startId }) ?? 0
        _selection = State(initialValue: startIndex)
    }

    var body: some View {
        GeometryReader { geometry in
            let windowInsets = UIApplication.currentKeyWindowSafeAreaInsets
            let safeTopInset = max(geometry.safeAreaInsets.top, windowInsets.top)
            let safeBottomInset = max(geometry.safeAreaInsets.bottom, windowInsets.bottom)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                Group {
                    if items.indices.contains(selection) {
                        MediaZoomDetailPage(
                            item: items[selection],
                            safeTopInset: safeTopInset,
                            safeBottomInset: safeBottomInset,
                            isVerticalDragging: $isVerticalDragging,
                            onShowPrevious: { showPrevious(containerWidth: geometry.size.width) },
                            onShowNext: { showNext(containerWidth: geometry.size.width) },
                            onClose: { handleClose() }
                        )
                        .id(items[selection].id)
                        .offset(x: pageSlideOffset)
                    }
                }
                .background(Color.black)
                .ignoresSafeArea()
                .allowsHitTesting(!isVerticalDragging && !isPageAnimating)

                Button {
                    showMetadata = true
                } label: {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Metadata")
                .padding(.top, safeTopInset > 0 ? safeTopInset + 24 : 56)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(30)
                .allowsHitTesting(!isVerticalDragging && !isPageAnimating)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showMetadata) {
            if let item = currentItem {
                MediaMetadataInfoSheet(item: item)
                    .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: selection) { _, newIndex in
            if newIndex >= items.count - 2 {
                onReachEnd?()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .background {
            Color.black.ignoresSafeArea()
        }
    }

    private func handleClose() {
        dismiss()
    }

    private var currentItem: MediaItem? {
        guard items.indices.contains(selection) else { return nil }
        return items[selection]
    }

    private func showPrevious(containerWidth: CGFloat) {
        guard selection > 0 else { return }
        animatePageChange(
            to: selection - 1,
            direction: .previous,
            containerWidth: containerWidth
        )
    }

    private func showNext(containerWidth: CGFloat) {
        let next = selection + 1
        guard items.indices.contains(next) else {
            onReachEnd?()
            return
        }
        animatePageChange(
            to: next,
            direction: .next,
            containerWidth: containerWidth
        )
    }

    private func animatePageChange(to targetIndex: Int, direction: PageDirection, containerWidth: CGFloat) {
        guard !isPageAnimating else { return }
        guard items.indices.contains(targetIndex) else { return }

        let width = max(1, containerWidth)
        let outboundOffset: CGFloat = direction == .next ? -width : width
        let inboundOffset: CGFloat = -outboundOffset
        isPageAnimating = true

        withAnimation(.easeInOut(duration: 0.15)) {
            pageSlideOffset = outboundOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            selection = targetIndex
            pageSlideOffset = inboundOffset
            withAnimation(.easeInOut(duration: 0.20)) {
                pageSlideOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                isPageAnimating = false
            }
        }
    }
}

private enum PageDirection {
    case previous
    case next
}

private extension UIApplication {
    static var currentKeyWindowSafeAreaInsets: UIEdgeInsets {
        let scenes = shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets ?? .zero
    }
}

struct MediaZoomDetailPage: View {
    let item: MediaItem
    let safeTopInset: CGFloat
    let safeBottomInset: CGFloat
    @Binding var isVerticalDragging: Bool
    let onShowPrevious: () -> Void
    let onShowNext: () -> Void
    let onClose: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var dragAxis: DragAxis? = nil
    @State private var zoomScale: CGFloat = 1

    private var bestURL: URL? {
        let candidate = item.urlLarge ?? item.urlMedium ?? item.urlThumb ?? item.url
        return URL(string: candidate)
    }

    private var resolvedURL: URL? {
        resolveURL(bestURL)
    }

    private var dragProgress: CGFloat {
        min(abs(dragOffset.height) / 300, 1.0)
    }

    private var backgroundOpacity: Double {
        1.0 - Double(dragProgress)
    }

    private var backgroundBlurRadius: CGFloat {
        16 + dragProgress * 18
    }

    private var backgroundScale: CGFloat {
        1.05 + dragProgress * 0.04
    }

    private var imageScale: CGFloat {
        1.0 - dragProgress * 0.08
    }

    private var controlsOpacity: Double {
        max(0, 1.0 - Double(dragProgress) * 1.2)
    }

    private var closeButtonTopPadding: CGFloat {
        safeTopInset > 0 ? safeTopInset + 24 : 56
    }

    private var isDragging: Bool {
        dragAxis == .vertical && abs(dragOffset.height) > 0.1
    }

    var body: some View {
        GeometryReader { proxy in
            let containerRect = CGRect(origin: .zero, size: proxy.size)
            let imageRect = aspectFitRect(
                image: CGSize(width: CGFloat(item.width ?? 0), height: CGFloat(item.height ?? 0)),
                in: containerRect
            )

            ZStack(alignment: .bottom) {
                // 背景层 - 不响应拖动
                if let backgroundURL = resolvedURL ?? bestURL {
                    RemoteImage(
                        url: backgroundURL,
                        contentMode: .fill,
                        fadeDuration: 0.15,
                        showsProgress: false,
                        disableAnimations: true
                    )
                    .blur(radius: backgroundBlurRadius)
                    .saturation(0.94)
                    .scaleEffect(backgroundScale)
                    .overlay(Color.black.opacity(0.12))
                    .opacity(backgroundOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                } else {
                    Color.black
                        .opacity(backgroundOpacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                }

                // 图片层 - 只有这里移动
                ZoomableImageView(
                    url: resolvedURL ?? bestURL,
                    zoomScale: $zoomScale
                )
                .frame(width: imageRect.width, height: imageRect.height)
                .position(x: imageRect.midX, y: imageRect.midY)
                .offset(x: dragOffset.width, y: dragOffset.height)
                .scaleEffect(imageScale)
                .contentShape(Rectangle())
                .simultaneousGesture(dragGesture)

                // 关闭按钮
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .opacity(controlsOpacity)
                .allowsHitTesting(!isDragging)
                .padding(.top, closeButtonTopPadding)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .zIndex(10)

            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    private func resolveURL(_ url: URL?) -> URL? {
        guard let url else { return nil }
        if url.scheme != nil {
            return url
        }
        return URL(string: url.absoluteString, relativeTo: AppConfig.baseURL)?.absoluteURL
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoomScale <= 1.01 else { return }
                let translation = value.translation
                if dragAxis == nil {
                    if abs(translation.width) < 8 && abs(translation.height) < 8 {
                        return
                    }
                    dragAxis = abs(translation.height) > abs(translation.width) ? .vertical : .horizontal
                    if dragAxis == .vertical {
                        isVerticalDragging = true
                    }
                }
                guard dragAxis == .vertical else { return }
                dragOffset = translation
            }
            .onEnded { value in
                let axis = dragAxis
                dragAxis = nil
                isVerticalDragging = false

                guard zoomScale <= 1.01 else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                    return
                }

                guard axis == .vertical else {
                    handleHorizontalSwipe(value)
                    return
                }

                let isDownward = value.translation.height > 0 || value.predictedEndTranslation.height > 0
                let closeThreshold: CGFloat = 100
                let predictedThreshold: CGFloat = 300
                let shouldTrigger = isDownward && (
                    value.translation.height > closeThreshold ||
                    value.predictedEndTranslation.height > predictedThreshold
                )
                if shouldTrigger {
                    onClose()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func handleHorizontalSwipe(_ value: DragGesture.Value) {
        let translation = value.translation.width
        let predicted = value.predictedEndTranslation.width
        let triggerDistance: CGFloat = 56
        let predictedDistance: CGFloat = 120

        if translation <= -triggerDistance || predicted <= -predictedDistance {
            onShowNext()
        } else if translation >= triggerDistance || predicted >= predictedDistance {
            onShowPrevious()
        }
    }

    private func aspectFitRect(image: CGSize, in rect: CGRect) -> CGRect {
        guard image.width > 0, image.height > 0 else {
            return rect
        }
        let scale = min(rect.width / image.width, rect.height / image.height)
        let size = CGSize(width: image.width * scale, height: image.height * scale)
        let origin = CGPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }
}

private enum DragAxis {
    case vertical
    case horizontal
}

private struct MediaMetadataInfoSheet: View {
    let item: MediaItem

    @Environment(\.dismiss) private var dismiss
    @StateObject private var downloadAccessViewModel = DownloadAccessViewModel()
    @State private var contentHeight: CGFloat = 260
    @State private var showPaywall = false
    @State private var showMessageAlert = false
    @State private var messageText = ""
    @State private var isSaving = false

    private var fittedDetentHeight: CGFloat {
        let windowInsets = UIApplication.currentKeyWindowSafeAreaInsets
        let topBarHeight: CGFloat = 56
        let minHeight: CGFloat = 240
        let maxHeight = UIScreen.main.bounds.height - max(windowInsets.top, 0) - 20
        let ideal = contentHeight + topBarHeight + windowInsets.bottom
        return min(max(ideal, minHeight), max(minHeight, maxHeight))
    }

    private var isBusy: Bool {
        isSaving || downloadAccessViewModel.isProcessing
    }

    private var downloadURL: URL? {
        let candidate = item.urlLarge ?? item.urlMedium ?? item.urlThumb ?? item.url
        guard let url = URL(string: candidate) else { return nil }
        if url.scheme != nil {
            return url
        }
        return URL(string: url.absoluteString, relativeTo: AppConfig.baseURL)?.absoluteURL
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                MediaItemInfoView(item: item)
                    .padding(16)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: MetadataContentHeightPreferenceKey.self,
                                    value: proxy.size.height
                                )
                        }
                    )
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await handleDownloadTap() }
                    } label: {
                        if isBusy {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("下载", systemImage: "arrow.down.circle")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    .disabled(downloadURL == nil || isBusy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(fittedDetentHeight), .large])
        .presentationContentInteraction(.scrolls)
        .task {
            await downloadAccessViewModel.prepare()
        }
        .onPreferenceChange(MetadataContentHeightPreferenceKey.self) { newValue in
            guard newValue > 0 else { return }
            let rounded = ceil(newValue)
            if abs(contentHeight - rounded) > 1 {
                contentHeight = rounded
            }
        }
        .sheet(isPresented: $showPaywall) {
            DownloadPaywallView(viewModel: downloadAccessViewModel) {
                Task { await saveImageToLibrary() }
            }
        }
        .alert("下载提示", isPresented: $showMessageAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(messageText)
        }
    }

    @MainActor
    private func handleDownloadTap() async {
        guard downloadURL != nil else {
            presentMessage("图片地址无效")
            return
        }
        if downloadAccessViewModel.isPurchased {
            await saveImageToLibrary()
        } else {
            showPaywall = true
        }
    }

    @MainActor
    private func saveImageToLibrary() async {
        guard let url = downloadURL else {
            presentMessage("图片地址无效")
            return
        }
        isSaving = true
        defer { isSaving = false }

        let hasPermission = await requestPhotoAccess()
        guard hasPermission else {
            presentMessage(String(localized: "Photo library access denied"))
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                presentMessage(String(localized: "Failed to save"))
                return
            }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            presentMessage(String(localized: "Saved to Photos"))
        } catch {
            presentMessage(String(localized: "Download failed"))
        }
    }

    private func requestPhotoAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    continuation.resume(returning: newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            return false
        }
    }

    @MainActor
    private func presentMessage(_ text: String) {
        messageText = text
        showMessageAlert = true
    }
}

private struct MetadataContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct MediaZoomPagerPreviewWrapper: View {
    @Namespace private var namespace

    var body: some View {
        MediaZoomPagerView(
            items: [
                MediaItem(id: "1", url: "https://example.com/1.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 1200, height: 800, likes: 0, liked: false, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil),
                MediaItem(id: "2", url: "https://example.com/2.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: 0, liked: false, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil)
            ],
            startId: "1",
            namespace: namespace
        )
    }
}

struct MediaZoomPagerView_Previews: PreviewProvider {
    static var previews: some View {
        MediaZoomPagerPreviewWrapper()
    }
}

private struct MetadataDrawer: View {
    let item: MediaItem?
    @Binding var height: CGFloat
    let collapsedHeight: CGFloat
    let mediumHeight: CGFloat
    let expandedHeight: CGFloat
    let bottomInset: CGFloat
    @State private var dragStartHeight: CGFloat? = nil
    @State private var likeViewModel: MediaLikeViewModel?

    private var currentHeight: CGFloat { height }
    private var anchors: [CGFloat] { [collapsedHeight, mediumHeight, expandedHeight] }
    private var isExpanded: Bool { height > collapsedHeight + 6 }
    private var effectiveBottomInset: CGFloat {
        // Prefer dynamic safe area from either parent geometry or key window.
        let windowBottom = UIApplication.currentKeyWindowSafeAreaInsets.bottom
        let resolvedBottom = max(bottomInset, windowBottom)
        return resolvedBottom > 0 ? resolvedBottom : 8
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleHeight()
                    }

                HStack {
                    Button {
                        cycleHeight()
                    } label: {
                        Text("Metadata", bundle: .main)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if let likeViewModel {
                        HStack(spacing: 8) {
                            if likeViewModel.likes > 0 {
                                Text("♥︎ \(likeViewModel.likes)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Button {
                                Task { await likeViewModel.toggle() }
                            } label: {
                                Group {
                                    if likeViewModel.isLoading {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: likeViewModel.liked ? "heart.fill" : "heart")
                                            .font(.body)
                                            .foregroundStyle(likeViewModel.liked ? .pink : .secondary)
                                    }
                                }
                                .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .disabled(likeViewModel.isLoading)
                        }
                    }
                }
                .padding(.bottom, 2)

                if let message = likeViewModel?.errorMessage, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                if let item {
                    MediaItemInfoView(item: item)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .opacity(isExpanded ? 1 : 0)

            Spacer(minLength: 0)
        }
        .padding(.bottom, effectiveBottomInset)
        .frame(height: currentHeight + effectiveBottomInset)
        .background(.ultraThinMaterial)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 22, bottomLeading: 0, bottomTrailing: 0, topTrailing: 22),
                style: .continuous
            )
        )
        .gesture(
            DragGesture(minimumDistance: 12, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartHeight == nil {
                        dragStartHeight = height
                    }
                    let base = dragStartHeight ?? height
                    let next = clampHeight(base - value.translation.height)
                    height = next
                }
                .onEnded { value in
                    let base = dragStartHeight ?? height
                    dragStartHeight = nil
                    let projected = clampHeight(base - value.predictedEndTranslation.height)
                    let target = nearestAnchor(to: projected)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        height = target
                    }
                }
        )
        .onAppear {
            height = nearestAnchor(to: height)
        }
        .task(id: item?.id) {
            guard let item else {
                likeViewModel = nil
                return
            }
            let vm = MediaLikeViewModel(mediaId: item.id)
            likeViewModel = vm
            await vm.load()
        }
    }

    private func clampHeight(_ value: CGFloat) -> CGFloat {
        min(max(value, collapsedHeight), expandedHeight)
    }

    private func nearestAnchor(to value: CGFloat) -> CGFloat {
        anchors.min(by: { abs($0 - value) < abs($1 - value) }) ?? collapsedHeight
    }

    private func cycleHeight() {
        let next: CGFloat
        if abs(height - collapsedHeight) < 2 {
            next = mediumHeight
        } else if abs(height - mediumHeight) < 2 {
            next = expandedHeight
        } else {
            next = collapsedHeight
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            height = next
        }
    }
}
