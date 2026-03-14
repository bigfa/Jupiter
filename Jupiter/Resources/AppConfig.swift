import Foundation

enum AlbumLikeButtonVisualStyle {
    case solidWhite
    case frosted
}

enum AppConfig {
    // TODO: Replace with your production base URL.
    static let baseURL = URL(string: "https://w.wpista.com")!
    static let defaultLocale = "zh"
    static let downloadUnlockProductID = "com.bigfa.jupiter.download.unlock"
    static let proEntitlementCacheKey = "com.bigfa.jupiter.pro.unlocked"
    static let albumLikeButtonStyle: AlbumLikeButtonVisualStyle = .frosted
}
