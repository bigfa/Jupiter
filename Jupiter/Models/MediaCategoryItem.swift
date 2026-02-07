import Foundation

struct MediaCategoryItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let slug: String
    let count: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case count
    }
}

struct MediaCategoriesResponse: Codable {
    let ok: Bool
    let categories: [MediaCategoryItem]
}
