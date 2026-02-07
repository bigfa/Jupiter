import Foundation
import Combine

@MainActor
final class MediaLikeViewModel: ObservableObject {
    @Published private(set) var likes: Int = 0
    @Published private(set) var liked = false
    @Published private(set) var isLoading = false

    private let mediaId: String
    private let service = MediaService()

    init(mediaId: String) {
        self.mediaId = mediaId
    }

    func load() async {
        isLoading = true
        do {
            let response = try await service.fetchMediaLikes(id: mediaId)
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
            let response: MediaLikeResponse
            if liked {
                response = try await service.unlikeMedia(id: mediaId)
            } else {
                response = try await service.likeMedia(id: mediaId)
            }
            likes = response.likes
            liked = response.liked
        } catch {
            // ignore
        }
        isLoading = false
    }
}
