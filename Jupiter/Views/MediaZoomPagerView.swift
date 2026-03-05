import SwiftUI
import UIKit

struct MediaZoomPagerView: View {
    let items: [MediaItem]
    let namespace: Namespace.ID
    @State private var selection: Int
    let onReachEnd: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isVerticalDragging: Bool = false
    @State private var showMetadata = false

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

                TabView(selection: $selection) {
                    ForEach(items.indices, id: \.self) { index in
                        MediaZoomDetailPage(
                            item: items[index],
                            safeTopInset: safeTopInset,
                            safeBottomInset: safeBottomInset,
                            isVerticalDragging: $isVerticalDragging,
                            onShowPrevious: { showPrevious() },
                            onShowNext: { showNext() },
                            onClose: { handleClose() }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.black)
                .ignoresSafeArea()
                .allowsHitTesting(!isVerticalDragging)

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
                .allowsHitTesting(!isVerticalDragging)
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

    private func showPrevious() {
        guard selection > 0 else { return }
        withAnimation(.easeInOut(duration: 0.22)) {
            selection -= 1
        }
    }

    private func showNext() {
        let next = selection + 1
        guard items.indices.contains(next) else {
            onReachEnd?()
            return
        }
        withAnimation(.easeInOut(duration: 0.22)) {
            selection = next
        }
    }
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
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
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

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                MediaItemInfoView(item: item)
                    .padding(16)
            }
            .background(Color.white)
            .navigationTitle("Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
