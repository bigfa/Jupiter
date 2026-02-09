import SwiftUI
import MapKit
import UIKit
import Photos

struct MediaDetailView: View {
    let mediaId: String
    let preview: MediaItem?

    @StateObject private var viewModel: MediaDetailViewModel
    @State private var likeViewModel: MediaLikeViewModel

    init(mediaId: String, preview: MediaItem? = nil) {
        self.mediaId = mediaId
        self.preview = preview
        _viewModel = StateObject(wrappedValue: MediaDetailViewModel(mediaId: mediaId))
        _likeViewModel = State(initialValue: MediaLikeViewModel(mediaId: mediaId))
    }

    private var displayImageURL: URL? {
        if let media = viewModel.media {
            if let url = media.urlLarge ?? media.urlMedium ?? media.urlThumb {
                return URL(string: url)
            }
            return URL(string: media.url)
        }
        if let preview {
            let url = preview.urlLarge ?? preview.urlMedium ?? preview.urlThumb ?? preview.url
            return URL(string: url)
        }
        return nil
    }

    private var shareURL: URL? {
        if let media = viewModel.media {
            if let url = media.urlLarge ?? media.urlMedium ?? media.urlThumb {
                return URL(string: url)
            }
            return URL(string: media.url)
        }
        if let preview {
            let url = preview.urlLarge ?? preview.urlMedium ?? preview.urlThumb ?? preview.url
            return URL(string: url)
        }
        return nil
    }

    @State private var downloadMessage: String? = nil
    @State private var showDownloadAlert = false
    @State private var showZoom = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RemoteImage(url: displayImageURL, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 8) {
                            Button {
                                Task { await shareImage() }
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            Button {
                                Task { await downloadImage() }
                            } label: {
                                Image(systemName: "arrow.down.circle")
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(8)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showZoom = true
                    }

                HStack(spacing: 12) {
                    Button {
                        Task { await likeViewModel.toggle() }
                    } label: {
                        Label(likeViewModel.liked ? "已赞" : "点赞", systemImage: likeViewModel.liked ? "heart.fill" : "heart")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(likeViewModel.liked ? .pink : .accentColor)

                    if likeViewModel.likes > 0 {
                        Text("♥︎ \(likeViewModel.likes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let media = viewModel.media {
                    MediaDetailInfoView(media: media)
                } else if preview == nil, let message = viewModel.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .navigationTitle("照片")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            if viewModel.media == nil && !viewModel.isLoading {
                await viewModel.load()
            }
            await likeViewModel.load()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("下载提示", isPresented: $showDownloadAlert) {
            Button("确定") {
                downloadMessage = nil
                showDownloadAlert = false
            }
        } message: {
            Text(downloadMessage ?? "")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .fullScreenCover(isPresented: $showZoom) {
            ZoomViewer(url: resolvedShareURL)
        }
    }
}

extension MediaDetailView {
    @MainActor
    private func downloadImage() async {
        guard let url = resolvedShareURL else { return }
        do {
            let authorized = await requestPhotoAccess()
            if !authorized {
                downloadMessage = "未授权访问相册"
                showDownloadAlert = true
                return
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                downloadMessage = "已保存到相册"
            } else {
                downloadMessage = "保存失败"
            }
        } catch {
            downloadMessage = "下载失败"
        }
        showDownloadAlert = true
    }

    @MainActor
    private func shareImage() async {
        guard let url = resolvedShareURL else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let image = UIImage(data: data) {
            shareItems = [image]
        } else {
            shareItems = [url]
        }
        showShareSheet = true
    }

    private var resolvedShareURL: URL? {
        guard let candidate = shareURL else { return nil }
        if candidate.scheme != nil {
            return candidate
        }
        return URL(string: candidate.absoluteString, relativeTo: AppConfig.baseURL)?.absoluteURL
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
}

private struct MediaDetailInfoView: View {
    let media: MediaDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let filename = media.filename {
                Text(filename)
                    .font(.headline)
            }

            infoRow(label: "相机", value: [media.cameraMake, media.cameraModel].compactMap { $0 }.joined(separator: " "))
            infoRow(label: "镜头", value: media.lensModel)
            infoRow(label: "光圈", value: media.aperture)
            infoRow(label: "快门", value: media.shutterSpeed)
            infoRow(label: "ISO", value: media.iso)
            infoRow(label: "焦距", value: media.focalLength)
            infoRow(label: "尺寸", value: dimensionsText)
            infoRow(label: "长宽比", value: aspectRatioText)
            infoRow(label: "大小", value: fileSizeText)
            infoRow(label: "格式", value: media.mimeType)
            infoRow(label: "拍摄时间", value: formatDate(media.datetimeOriginal))
            infoRow(label: "上传时间", value: formatDate(media.createdAt))
            infoRow(label: "经纬度", value: coordinateText)
            infoRow(label: "位置", value: media.locationName)

            if let tags = media.tags, !tags.isEmpty {
                Text("标签: \(tags.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let categories = media.categories, !categories.isEmpty {
                Text("分类: \(categories.map { $0.name }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let coordinate = locationCoordinate {
                MediaLocationMap(coordinate: coordinate)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func infoRow(label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)
                Text(value)
                    .font(.caption)
            }
        }
    }

    private var dimensionsText: String? {
        guard let w = media.width, let h = media.height else { return nil }
        return "\(w) × \(h)"
    }

    private var aspectRatioText: String? {
        guard let w = media.width, let h = media.height, h != 0 else { return nil }
        let ratio = Double(w) / Double(h)
        return String(format: "%.2f", ratio)
    }

    private var fileSizeText: String? {
        guard let size = media.size else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private var coordinateText: String? {
        guard let lat = media.gpsLat, let lon = media.gpsLon else { return nil }
        return String(format: "%.5f, %.5f", lat, lon)
    }

    private var locationCoordinate: CLLocationCoordinate2D? {
        guard let lat = media.gpsLat, let lon = media.gpsLon else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func formatDate(_ value: String?) -> String? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return value
    }
}

private struct MediaLocationMap: View {
    let coordinate: CLLocationCoordinate2D

    @State private var position: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        _position = State(initialValue: .region(region))
    }

    var body: some View {
        Map(position: $position) {
            Marker("", coordinate: coordinate)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MediaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MediaDetailView(mediaId: "m_1", preview: MediaItem(
            id: "m_1",
            url: "https://example.com/1.jpg",
            urlThumb: nil,
            urlMedium: nil,
            urlLarge: nil,
            width: 1200,
            height: 800,
            likes: 12,
            liked: false,
            datetimeOriginal: nil,
            createdAt: nil
        ))
    }
}
