import SwiftUI
import UIKit

struct MediaMasonryCard: View {
    let item: MediaItem
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
            .background(Color(.secondarySystemBackground))
            .clipped()
            .overlay(alignment: .bottomLeading) {
                if let likes = item.likes, likes > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                        Text("\(likes)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(6)
                }
            }

        if let heroNamespace, isHero {
            image.matchedGeometryEffect(id: item.id, in: heroNamespace, isSource: true)
        } else {
            image
        }
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
            createdAt: nil
        ))
        .padding()
    }
}
