import Foundation

struct MediaItem: Identifiable, Codable, Hashable {
    let id: String
    let url: String
    let urlThumb: String?
    let urlMedium: String?
    let urlLarge: String?
    let width: Int?
    let height: Int?
    let likes: Int?
    let liked: Bool?
    let datetimeOriginal: String?
    let createdAt: String?
    let filename: String? = nil
    let size: Int? = nil
    let mimeType: String? = nil
    let cameraMake: String? = nil
    let cameraModel: String? = nil
    let lensModel: String? = nil
    let aperture: String? = nil
    let shutterSpeed: String? = nil
    let iso: String? = nil
    let focalLength: String? = nil
    let locationName: String? = nil
    let gpsLat: Double? = nil
    let gpsLon: Double? = nil
    let tags: [String]? = nil
    let categories: [MediaCategory]? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case urlThumb = "url_thumb"
        case urlMedium = "url_medium"
        case urlLarge = "url_large"
        case width
        case height
        case likes
        case liked
        case datetimeOriginal = "datetime_original"
        case createdAt = "created_at"
        case filename
        case size
        case mimeType = "mime_type"
        case cameraMake = "camera_make"
        case cameraModel = "camera_model"
        case lensModel = "lens_model"
        case aperture
        case shutterSpeed = "shutter_speed"
        case iso
        case focalLength = "focal_length"
        case locationName = "location_name"
        case gpsLat = "gps_lat"
        case gpsLon = "gps_lon"
        case tags
        case categories
    }
}

struct MediaListResponse: Codable {
    let ok: Bool
    let results: [MediaItem]
    let total: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case ok
        case results
        case total
        case page
        case pageSize
        case totalPages
    }
}
