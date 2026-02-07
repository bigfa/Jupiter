import Foundation

struct AlbumService {
    func fetchAlbums(page: Int, pageSize: Int, category: String? = nil) async throws -> AlbumListResponse {
        var query: [URLQueryItem] = [
            .init(name: "page", value: String(page)),
            .init(name: "pageSize", value: String(pageSize))
        ]
        if let category, !category.isEmpty {
            query.append(.init(name: "category", value: category))
        }
        return try await APIClient.shared.get(path: "/api/albums", query: query)
    }

    func fetchAlbumCategories() async throws -> MediaCategoriesResponse {
        return try await APIClient.shared.get(path: "/api/albums/categories")
    }

    func fetchAlbumDetail(id: String, token: String?) async throws -> AlbumDetailResponse {
        var headers: [String: String] = [:]
        if let token {
            headers["Authorization"] = "Bearer \(token)"
        }
        return try await APIClient.shared.get(path: "/api/albums/\(id)", headers: headers)
    }

    func fetchAlbumMedia(id: String, page: Int, pageSize: Int, token: String?) async throws -> AlbumMediaResponse {
        var headers: [String: String] = [:]
        if let token {
            headers["Authorization"] = "Bearer \(token)"
        }
        let query: [URLQueryItem] = [
            .init(name: "page", value: String(page)),
            .init(name: "pageSize", value: String(pageSize))
        ]
        return try await APIClient.shared.get(path: "/api/albums/\(id)/media", query: query, headers: headers)
    }

    func unlockAlbum(id: String, password: String) async throws -> AlbumUnlockResponse {
        struct Body: Encodable { let password: String }
        return try await APIClient.shared.post(path: "/api/albums/\(id)/unlock", body: Body(password: password))
    }

    func fetchAlbumLikes(id: String) async throws -> AlbumLikeResponse {
        return try await APIClient.shared.get(path: "/api/albums/\(id)/like")
    }

    func likeAlbum(id: String) async throws -> AlbumLikeResponse {
        struct Body: Encodable { let action: String }
        return try await APIClient.shared.post(path: "/api/albums/\(id)/like", body: Body(action: "like"))
    }

    func unlikeAlbum(id: String) async throws -> AlbumLikeResponse {
        return try await APIClient.shared.delete(path: "/api/albums/\(id)/like")
    }

    func fetchAlbumComments(id: String) async throws -> AlbumCommentsResponse {
        return try await APIClient.shared.get(path: "/api/albums/\(id)/comments")
    }

    func postAlbumComment(id: String, input: AlbumCommentInput) async throws -> AlbumCommentPostResponse {
        return try await APIClient.shared.post(path: "/api/albums/\(id)/comments", body: input)
    }
}

struct AlbumCommentInput: Encodable {
    let authorName: String
    let authorEmail: String
    let authorUrl: String?
    let content: String
    let parentId: String?

    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case authorEmail = "author_email"
        case authorUrl = "author_url"
        case content
        case parentId = "parent_id"
    }
}
