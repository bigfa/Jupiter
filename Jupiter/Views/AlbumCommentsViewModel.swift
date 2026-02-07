import Foundation
import Combine

@MainActor
final class AlbumCommentsViewModel: ObservableObject {
    @Published private(set) var comments: [AlbumComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String? = nil

    private let albumId: String
    private let service = AlbumService()

    init(albumId: String) {
        self.albumId = albumId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchAlbumComments(id: albumId)
            comments = response.comments
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func submit(name: String, email: String, url: String?, content: String, parentId: String?) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            let input = AlbumCommentInput(
                authorName: name,
                authorEmail: email,
                authorUrl: url?.isEmpty == true ? nil : url,
                content: content,
                parentId: parentId
            )
            _ = try await service.postAlbumComment(id: albumId, input: input)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
