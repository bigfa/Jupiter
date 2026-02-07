import SwiftUI

struct AlbumCard: View {
    let album: AlbumListItem

    private var coverURL: URL? {
        if let cover = album.coverMedia {
            return URL(string: cover.urlMedium ?? cover.urlThumb ?? cover.url)
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: coverURL, contentMode: .fill)
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.05),
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(album.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let description = album.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.88))
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let count = album.mediaCount {
                        Text("\(count) 张")
                    }
                    if let likes = album.likes, likes > 0 {
                        Text("♥︎ \(likes)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.9))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)

            if album.isProtected == true {
                VStack {
                    HStack {
                        Spacer()
                        Label("私密", systemImage: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct AlbumCard_Previews: PreviewProvider {
    static var previews: some View {
        AlbumCard(album: AlbumListItem(
            id: "a_1",
            title: "Japan 2024",
            description: "Tokyo & Kyoto",
            coverMedia: AlbumCoverMedia(id: "m_1", url: "https://example.com", urlThumb: nil, urlMedium: nil),
            mediaCount: 88,
            likes: 10,
            slug: "japan-2024",
            isProtected: true,
            categories: nil,
            categoryIds: nil
        ))
        .padding()
    }
}
