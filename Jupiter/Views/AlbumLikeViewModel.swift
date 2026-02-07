import Foundation
import Combine

@MainActor
final class AlbumLikeViewModel: ObservableObject {
    @Published private(set) var likes: Int = 0
    @Published private(set) var liked = false
    @Published private(set) var isLoading = false

    private let albumId: String
    private let service = AlbumService()

    init(albumId: String) {
        self.albumId = albumId
    }

    func load() async {
        isLoading = true
        do {
            let response = try await service.fetchAlbumLikes(id: albumId)
            likes = response.likes
            liked = response.liked
        } catch {
            // ignore error to avoid blocking UI
        }
        isLoading = false
    }

    func toggle() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let response: AlbumLikeResponse
            if liked {
                response = try await service.unlikeAlbum(id: albumId)
            } else {
                response = try await service.likeAlbum(id: albumId)
            }
            likes = response.likes
            liked = response.liked
        } catch {
            // ignore
        }
        isLoading = false
    }
}
