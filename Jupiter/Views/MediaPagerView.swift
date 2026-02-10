import SwiftUI

struct MediaPagerView: View {
    let items: [MediaItem]
    @State private var selection: Int
    let onReachEnd: (() -> Void)?

    init(items: [MediaItem], startId: String, onReachEnd: (() -> Void)? = nil) {
        self.items = items
        self.onReachEnd = onReachEnd
        let startIndex = items.firstIndex(where: { $0.id == startId }) ?? 0
        _selection = State(initialValue: startIndex)
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(items.indices, id: \.self) { index in
                MediaDetailView(mediaId: items[index].id, preview: items[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: selection) { _, newIndex in
            if newIndex >= items.count - 2 {
                onReachEnd?()
            }
        }
    }
}

struct MediaPagerView_Previews: PreviewProvider {
    static var previews: some View {
        MediaPagerView(items: [
            MediaItem(id: "1", url: "https://example.com/1.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 1200, height: 800, likes: 0, liked: false, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil),
            MediaItem(id: "2", url: "https://example.com/2.jpg", urlThumb: nil, urlMedium: nil, urlLarge: nil, width: 800, height: 1200, likes: 0, liked: false, datetimeOriginal: nil, createdAt: nil, filename: nil, size: nil, mimeType: nil, cameraMake: nil, cameraModel: nil, lensModel: nil, aperture: nil, shutterSpeed: nil, iso: nil, focalLength: nil, locationName: nil, gpsLat: nil, gpsLon: nil, tags: nil, categories: nil)
        ], startId: "1")
    }
}
