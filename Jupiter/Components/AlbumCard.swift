import SwiftUI

struct AlbumCardStatItem: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let isAccent: Bool
}

enum AlbumCardPresentation {
    static func subtitle(for album: AlbumListItem) -> String {
        if let description = album.description?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !description.isEmpty {
            return description
        }

        let categoryNames = (album.categories ?? [])
            .map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !categoryNames.isEmpty {
            return categoryNames.joined(separator: " · ")
        }

        return "慢慢整理你的照片收藏"
    }

    static func statItems(for album: AlbumListItem) -> [AlbumCardStatItem] {
        var items: [AlbumCardStatItem] = []

        if let mediaCount = album.mediaCount, mediaCount > 0 {
            items.append(
                AlbumCardStatItem(
                    id: "mediaCount",
                    title: "\(mediaCount) 张照片",
                    systemImage: "photo.on.rectangle.angled",
                    isAccent: false
                )
            )
        }

        if let likes = album.likes, likes > 0 {
            items.append(
                AlbumCardStatItem(
                    id: "likes",
                    title: "\(likes) 喜欢",
                    systemImage: "heart.fill",
                    isAccent: false
                )
            )
        }

        if album.isProtected == true {
            items.append(
                AlbumCardStatItem(
                    id: "protected",
                    title: "受保护",
                    systemImage: "lock.fill",
                    isAccent: true
                )
            )
        }

        if items.isEmpty {
            items.append(
                AlbumCardStatItem(
                    id: "album",
                    title: "相册",
                    systemImage: "photo.stack.fill",
                    isAccent: false
                )
            )
        }

        return items
    }
}

struct AlbumCard: View {
    let album: AlbumListItem
    private let coverHeight: CGFloat = 182

    private var coverURL: URL? {
        if let cover = album.coverMedia {
            return URL(string: cover.urlMedium ?? cover.urlThumb ?? cover.url)
        }
        return nil
    }

    private var subtitle: String {
        AlbumCardPresentation.subtitle(for: album)
    }

    private var statItems: [AlbumCardStatItem] {
        AlbumCardPresentation.statItems(for: album)
    }

    var body: some View {
        VStack(spacing: 0) {
            coverSection
            infoStrip
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CinematicPalette.warmSurface.opacity(0.92))
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var coverSection: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if coverURL != nil {
                    RemoteImage(url: coverURL, contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(red: 0.91, green: 0.88, blue: 0.82),
                                Color(red: 0.85, green: 0.77, blue: 0.68)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                }
            }
            .frame(height: coverHeight)
            .frame(maxWidth: .infinity)
            .background(CinematicPalette.warmCanvas)
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color.clear,
                        Color.black.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .overlay(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.10)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            .clipped()

            if album.isProtected == true {
                Text("受保护")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.64))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(CinematicPalette.warmSurface.opacity(0.82))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .padding(14)
            }
        }
    }

    private var infoStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(album.title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .tracking(0.2)
                .foregroundStyle(Color.black.opacity(0.86))
                .lineLimit(2)

            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.58))
                .lineLimit(2)
                .lineSpacing(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(statItems) { item in
                        statPill(item)
                    }
                }
            }
            .scrollDisabled(true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CinematicPalette.warmSurface.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)
        }
    }

    private func statPill(_ item: AlbumCardStatItem) -> some View {
        HStack(spacing: 6) {
            Image(systemName: item.systemImage)
                .font(.caption2.weight(.semibold))
            Text(item.title)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(
            item.isAccent
            ? Color(red: 0.79, green: 0.47, blue: 0.17)
            : Color.black.opacity(0.62)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(
                    item.isAccent
                    ? Color(red: 0.97, green: 0.90, blue: 0.79)
                    : CinematicPalette.warmCanvas
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.black.opacity(item.isAccent ? 0.04 : 0.03), lineWidth: 1)
        )
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
