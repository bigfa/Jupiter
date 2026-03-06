import SwiftUI

struct AlbumCard: View {
    let album: AlbumListItem
    private let cardHeight: CGFloat = 236

    private var coverURL: URL? {
        if let cover = album.coverMedia {
            return URL(string: cover.urlMedium ?? cover.urlThumb ?? cover.url)
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: coverURL, contentMode: .fill)
                .frame(height: cardHeight)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.02),
                            Color.black.opacity(0.12),
                            Color.black.opacity(0.38),
                            Color.black.opacity(0.72)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.20),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(album.title)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .tracking(0.2)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)

                if let description = album.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .lineLimit(2)
                        .lineSpacing(1.5)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            if album.isProtected == true {
                VStack {
                    HStack {
                        Spacer()
                        Label("Locked", systemImage: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.22))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
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
