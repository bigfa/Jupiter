import Foundation

struct MediaService {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchMedia(page: Int, pageSize: Int, category: String?, sort: String) async throws -> MediaListResponse {
        var query: [URLQueryItem] = [
            .init(name: "page", value: String(page)),
            .init(name: "pageSize", value: String(pageSize)),
            .init(name: "sort", value: sort)
        ]
        if let category, !category.isEmpty {
            query.append(.init(name: "category", value: category))
        }
        return try await client.get(path: "/api/media/list", query: query)
    }

    func fetchCategories() async throws -> MediaCategoriesResponse {
        return try await client.get(path: "/api/media/categories")
    }

    func fetchMediaDetail(id: String) async throws -> MediaDetailResponse {
        return try await client.get(path: "/api/media/\(id)")
    }

    func fetchMediaLikes(id: String) async throws -> MediaLikeResponse {
        return try await client.get(path: "/api/media/\(id)/like")
    }

    func likeMedia(id: String) async throws -> MediaLikeResponse {
        struct Body: Encodable { let action: String }
        return try await client.post(path: "/api/media/\(id)/like", body: Body(action: "like"))
    }

    func unlikeMedia(id: String) async throws -> MediaLikeResponse {
        return try await client.delete(path: "/api/media/\(id)/like")
    }
}
