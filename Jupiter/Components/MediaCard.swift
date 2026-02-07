import SwiftUI

struct MediaCard: View {
    let item: MediaItem

    private var bestURL: URL? {
        if let url = item.urlThumb ?? item.urlMedium ?? item.urlLarge {
            return URL(string: url)
        }
        return URL(string: item.url)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    RemoteImage(url: bestURL, contentMode: .fill)
                        .clipped()
                }
                .clipped()

            if let likes = item.likes, likes > 0 {
                Text("♥︎ \(likes)")
                    .font(.caption)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MediaCard_Previews: PreviewProvider {
    static var previews: some View {
        MediaCard(item: MediaItem(
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
        .padding()
    }
}
