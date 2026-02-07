import Foundation

final class AlbumTokenStore {
    static let shared = AlbumTokenStore()

    private let keyPrefix = "album_token_"
    private let defaults = UserDefaults.standard

    func token(for albumId: String) -> String? {
        defaults.string(forKey: keyPrefix + albumId)
    }

    func setToken(_ token: String, for albumId: String) {
        defaults.set(token, forKey: keyPrefix + albumId)
    }
}
