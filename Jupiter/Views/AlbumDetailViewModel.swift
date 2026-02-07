import Foundation
import Combine

@MainActor
final class AlbumDetailViewModel: ObservableObject {
    @Published private(set) var album: AlbumDetail? = nil
    @Published private(set) var media: [MediaItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil
    @Published var requiresPassword = false

    private let albumId: String
    private let service = AlbumService()
    private let tokenStore = AlbumTokenStore.shared

    private var page = 1
    private var total = 0
    private let pageSize = 50

    private var token: String? {
        tokenStore.token(for: albumId)
    }

    init(albumId: String) {
        self.albumId = albumId
    }

    func loadInitial() async {
        page = 1
        media = []
        await loadAlbumDetail()
        await loadMediaPage(1)
    }

    func loadMoreIfNeeded(current item: MediaItem) async {
        guard let last = media.last, last.id == item.id else { return }
        guard !isLoading else { return }
        if media.count >= total && total > 0 { return }
        await loadMediaPage(page + 1)
    }

    func loadNextPageIfPossible() async {
        guard !isLoading else { return }
        if media.count >= total && total > 0 { return }
        await loadMediaPage(page + 1)
    }

    func unlock(password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.unlockAlbum(id: albumId, password: password)
            tokenStore.setToken(response.token, for: albumId)
            requiresPassword = false
            await loadInitial()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadAlbumDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchAlbumDetail(id: albumId, token: token)
            album = response.data
            requiresPassword = false
        } catch {
            if let apiError = error as? APIError, apiError.statusCode == 403 {
                requiresPassword = true
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    private func loadMediaPage(_ targetPage: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchAlbumMedia(id: albumId, page: targetPage, pageSize: pageSize, token: token)
            if targetPage == 1 {
                media = response.media
            } else {
                media.append(contentsOf: response.media)
            }
            page = targetPage
            total = response.total ?? media.count
        } catch {
            if let apiError = error as? APIError, apiError.statusCode == 403 {
                requiresPassword = true
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}
