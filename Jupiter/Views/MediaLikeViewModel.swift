import Foundation
import Combine

@MainActor
final class MediaLikeViewModel: ObservableObject {
    @Published private(set) var likes: Int = 0
    @Published private(set) var liked = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let mediaId: String
    private let service: MediaService
    private var latestRequestID = UUID()

    init(mediaId: String, service: MediaService) {
        self.mediaId = mediaId
        self.service = service
    }

    convenience init(mediaId: String) {
        self.init(mediaId: mediaId, service: MediaService())
    }

    func load() async {
        let requestID = UUID()
        latestRequestID = requestID
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchMediaLikes(id: mediaId)
            if latestRequestID == requestID {
                likes = response.likes
                liked = response.liked
            }
        } catch {
            if latestRequestID == requestID {
                errorMessage = readableMessage(from: error)
            }
        }
        if latestRequestID == requestID {
            isLoading = false
        }
    }

    func toggle() async {
        guard !isLoading else { return }
        let requestID = UUID()
        latestRequestID = requestID
        isLoading = true
        errorMessage = nil
        do {
            let response: MediaLikeResponse
            if liked {
                response = try await service.unlikeMedia(id: mediaId)
            } else {
                response = try await service.likeMedia(id: mediaId)
            }
            if latestRequestID == requestID {
                likes = response.likes
                liked = response.liked
            }
        } catch {
            if latestRequestID == requestID {
                errorMessage = readableMessage(from: error)
            }
        }
        if latestRequestID == requestID {
            isLoading = false
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func readableMessage(from error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }
        return "点赞请求失败，请稍后重试"
    }
}
