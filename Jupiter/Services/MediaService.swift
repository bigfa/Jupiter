import Foundation

struct MediaService {
    func fetchMedia(page: Int, pageSize: Int, category: String?, sort: String) async throws -> MediaListResponse {
        var query: [URLQueryItem] = [
            .init(name: "page", value: String(page)),
            .init(name: "pageSize", value: String(pageSize)),
            .init(name: "sort", value: sort)
        ]
        if let category, !category.isEmpty {
            query.append(.init(name: "category", value: category))
        }
        return try await APIClient.shared.get(path: "/api/media/list", query: query)
    }

    func fetchCategories() async throws -> MediaCategoriesResponse {
        return try await APIClient.shared.get(path: "/api/media/categories")
    }

    func fetchMediaDetail(id: String) async throws -> MediaDetailResponse {
        return try await APIClient.shared.get(path: "/api/media/\(id)")
    }

    func fetchMediaLikes(id: String) async throws -> MediaLikeResponse {
        return try await APIClient.shared.get(path: "/api/media/\(id)/like")
    }

    func likeMedia(id: String) async throws -> MediaLikeResponse {
        struct Body: Encodable { let action: String }
        return try await APIClient.shared.post(path: "/api/media/\(id)/like", body: Body(action: "like"))
    }

    func unlikeMedia(id: String) async throws -> MediaLikeResponse {
        return try await APIClient.shared.delete(path: "/api/media/\(id)/like")
    }
}
