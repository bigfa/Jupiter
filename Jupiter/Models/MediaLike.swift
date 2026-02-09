import Foundation

struct MediaLikeResponse: Codable {
    let ok: Bool
    let likes: Int
    let liked: Bool
}
