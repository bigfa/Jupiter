import SwiftUI
import UIKit

enum MediaMasonryCardStyle {
    case plain
    case editorial
}

struct MediaMasonryCard: View {
    let item: MediaItem
    var style: MediaMasonryCardStyle = .plain
    var showsLikesBadge = true
    var heroNamespace: Namespace.ID? = nil
    var isHero: Bool = false
    var onImageLoaded: ((UIImage) -> Void)? = nil

    private var bestURL: URL? {
        if let url = item.urlThumb ?? item.urlMedium ?? item.urlLarge {
            return URL(string: url)
        }
        return URL(string: item.url)
    }

    private var aspectRatio: CGFloat {
        guard let w = item.width, let h = item.height, w > 0, h > 0 else {
            return 1
        }
        return CGFloat(w) / CGFloat(h)
    }

    var body: some View {
        let image = LazyRemoteImage(
            url: bestURL,
            contentMode: .fill,
            aspectRatio: aspectRatio,
            onImageLoaded: { image in
                onImageLoaded?(image)
            }
        )
            .frame(maxWidth: .infinity)
            .background(CinematicPalette.warmCanvas)
            .clipped()

        let content = Group {
            switch style {
            case .plain:
                image
            case .editorial:
                editorialCard(image: image)
            }
        }

        if let heroNamespace, isHero {
            content.matchedGeometryEffect(id: item.id, in: heroNamespace, isSource: true)
        } else {
            content
        }
    }

    private func editorialCard<Content: View>(image: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            image
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.clear,
                            Color.black.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

            if showsLikesBadge, let likes = item.likes, likes > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "heart.fill")
                        .font(.caption2.weight(.semibold))
                    Text("\(likes)")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.black.opacity(0.64))
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(CinematicPalette.warmSurface.opacity(0.88))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 14, x: 0, y: 8)
    }
}

struct MediaMasonryCard_Previews: PreviewProvider {
    static var previews: some View {
        MediaMasonryCard(item: MediaItem(
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
            createdAt: nil,
            filename: nil,
            size: nil,
            mimeType: nil,
            cameraMake: nil,
            cameraModel: nil,
            lensModel: nil,
            aperture: nil,
            shutterSpeed: nil,
            iso: nil,
            focalLength: nil,
            locationName: nil,
            gpsLat: nil,
            gpsLon: nil,
            tags: nil,
            categories: nil
        ))
        .padding()
    }
}
