import Foundation

struct AlbumLikeResponse: Codable {
    let ok: Bool
    let likes: Int
    let liked: Bool
}
