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
    let filename: String?
    let size: Int?
    let mimeType: String?
    let cameraMake: String?
    let cameraModel: String?
    let lensModel: String?
    let aperture: String?
    let shutterSpeed: String?
    let iso: String?
    let focalLength: String?
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

    init(
        id: String,
        url: String,
        urlThumb: String?,
        urlMedium: String?,
        urlLarge: String?,
        width: Int?,
        height: Int?,
        likes: Int?,
        liked: Bool?,
        datetimeOriginal: String?,
        createdAt: String?,
        filename: String?,
        size: Int?,
        mimeType: String?,
        cameraMake: String?,
        cameraModel: String?,
        lensModel: String?,
        aperture: String?,
        shutterSpeed: String?,
        iso: String?,
        focalLength: String?,
        locationName: String?,
        gpsLat: Double?,
        gpsLon: Double?,
        tags: [String]?,
        categories: [MediaCategory]?
    ) {
        self.id = id
        self.url = url
        self.urlThumb = urlThumb
        self.urlMedium = urlMedium
        self.urlLarge = urlLarge
        self.width = width
        self.height = height
        self.likes = likes
        self.liked = liked
        self.datetimeOriginal = datetimeOriginal
        self.createdAt = createdAt
        self.filename = filename
        self.size = size
        self.mimeType = mimeType
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.lensModel = lensModel
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.iso = iso
        self.focalLength = focalLength
        self.locationName = locationName
        self.gpsLat = gpsLat
        self.gpsLon = gpsLon
        self.tags = tags
        self.categories = categories
    }

    init(detail: MediaDetail, fallback: MediaItem) {
        self.init(
            id: detail.id,
            url: detail.url,
            urlThumb: detail.urlThumb ?? fallback.urlThumb,
            urlMedium: detail.urlMedium ?? fallback.urlMedium,
            urlLarge: detail.urlLarge ?? fallback.urlLarge,
            width: detail.width ?? fallback.width,
            height: detail.height ?? fallback.height,
            likes: fallback.likes,
            liked: fallback.liked,
            datetimeOriginal: detail.datetimeOriginal ?? fallback.datetimeOriginal,
            createdAt: detail.createdAt ?? fallback.createdAt,
            filename: detail.filename ?? fallback.filename,
            size: detail.size ?? fallback.size,
            mimeType: detail.mimeType ?? fallback.mimeType,
            cameraMake: detail.cameraMake ?? fallback.cameraMake,
            cameraModel: detail.cameraModel ?? fallback.cameraModel,
            lensModel: detail.lensModel ?? fallback.lensModel,
            aperture: detail.aperture ?? fallback.aperture,
            shutterSpeed: detail.shutterSpeed ?? fallback.shutterSpeed,
            iso: detail.iso ?? fallback.iso,
            focalLength: detail.focalLength ?? fallback.focalLength,
            locationName: detail.locationName ?? fallback.locationName,
            gpsLat: detail.gpsLat ?? fallback.gpsLat,
            gpsLon: detail.gpsLon ?? fallback.gpsLon,
            tags: detail.tags ?? fallback.tags,
            categories: detail.categories ?? fallback.categories
        )
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
