import Foundation

struct AlbumComment: Identifiable, Codable, Hashable {
    let id: String
    let albumId: String
    let authorName: String?
    let authorUrl: String?
    let content: String
    let contentHtml: String?
    let createdAt: String?
    let parentId: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case albumId = "album_id"
        case authorName = "author_name"
        case authorUrl = "author_url"
        case content
        case contentHtml = "content_html"
        case createdAt = "created_at"
        case parentId = "parent_id"
        case status
    }
}

struct AlbumCommentsResponse: Codable {
    let ok: Bool
    let comments: [AlbumComment]
    let isAdmin: Bool?
}

struct AlbumCommentPostResponse: Codable {
    let ok: Bool
    let data: AlbumCommentPostData?
}

struct AlbumCommentPostData: Codable {
    let id: String
    let status: String
}
