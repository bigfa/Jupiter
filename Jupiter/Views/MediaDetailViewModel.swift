import Foundation
import Combine

@MainActor
final class MediaDetailViewModel: ObservableObject {
    @Published private(set) var media: MediaDetail? = nil
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil

    private let mediaId: String
    private let service = MediaService()

    init(mediaId: String) {
        self.mediaId = mediaId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchMediaDetail(id: mediaId)
            media = response.data
        } catch {
            if let apiError = error as? APIError, apiError.statusCode == 404 {
                // Detail endpoint may be unavailable; fall back to preview-only view.
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}
