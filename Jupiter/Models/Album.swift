import Foundation

struct AlbumCoverMedia: Codable, Hashable {
    let id: String
    let url: String
    let urlThumb: String?
    let urlMedium: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case urlThumb = "url_thumb"
        case urlMedium = "url_medium"
    }
}

struct AlbumListItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let coverMedia: AlbumCoverMedia?
    let mediaCount: Int?
    let likes: Int?
    let slug: String?
    let isProtected: Bool?
    let categories: [MediaCategoryItem]?
    let categoryIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case coverMedia = "cover_media"
        case mediaCount = "media_count"
        case likes
        case slug
        case isProtected = "is_protected"
        case categories
        case categoryIds = "category_ids"
    }
}

struct AlbumListResponse: Codable {
    let ok: Bool
    let albums: [AlbumListItem]
    let total: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case ok
        case albums
        case total
        case totalPages
    }
}

struct AlbumDetail: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let coverMedia: AlbumCoverMedia?
    let mediaCount: Int?
    let views: Int?
    let likes: Int?
    let slug: String?
    let isProtected: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case coverMedia = "cover_media"
        case mediaCount = "media_count"
        case views
        case likes
        case slug
        case isProtected = "is_protected"
    }
}

struct AlbumDetailResponse: Codable {
    let ok: Bool
    let data: AlbumDetail
}

struct AlbumMediaResponse: Codable {
    let ok: Bool
    let media: [MediaItem]
    let total: Int?
}

struct AlbumUnlockResponse: Codable {
    let ok: Bool
    let token: String
}
