import Foundation

struct MediaDetail: Identifiable, Codable, Hashable {
    let id: String
    let url: String
    let urlThumb: String?
    let urlMedium: String?
    let urlLarge: String?
    let filename: String?
    let size: Int?
    let mimeType: String?
    let width: Int?
    let height: Int?
    let createdAt: String?
    let cameraMake: String?
    let cameraModel: String?
    let lensModel: String?
    let aperture: String?
    let shutterSpeed: String?
    let iso: String?
    let focalLength: String?
    let datetimeOriginal: String?
    let locationName: String?
    let gpsLat: Double?
    let gpsLon: Double?
    let tags: [String]?
    let categories: [MediaCategory]?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case urlThumb = "url_thumb"
        case urlMedium = "url_medium"
        case urlLarge = "url_large"
        case filename
        case size
        case mimeType = "mime_type"
        case width
        case height
        case createdAt = "created_at"
        case cameraMake = "camera_make"
        case cameraModel = "camera_model"
        case lensModel = "lens_model"
        case aperture
        case shutterSpeed = "shutter_speed"
        case iso
        case focalLength = "focal_length"
        case datetimeOriginal = "datetime_original"
        case locationName = "location_name"
        case gpsLat = "gps_lat"
        case gpsLon = "gps_lon"
        case tags
        case categories
    }
}

struct MediaDetailResponse: Codable {
    let ok: Bool
    let data: MediaDetail
}

struct MediaCategory: Codable, Hashable {
    let id: String
    let name: String
}
