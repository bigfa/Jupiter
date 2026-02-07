import Foundation
import Combine

@MainActor
final class AlbumListViewModel: ObservableObject {
    @Published private(set) var albums: [AlbumListItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var categories: [MediaCategoryItem] = []
    @Published var selectedCategory: MediaCategoryItem? = nil

    private let service = AlbumService()
    private var page = 1
    private var totalPages = 1
    private let pageSize = 20

    var canLoadMore: Bool {
        page < totalPages && !isLoading
    }

    func loadInitial() async {
        page = 1
        totalPages = 1
        albums = []
        if categories.isEmpty {
            await loadCategories()
        }
        await loadPage(page)
    }

    func loadMoreIfNeeded(current item: AlbumListItem) async {
        guard let last = albums.last, last.id == item.id else { return }
        guard canLoadMore else { return }
        await loadPage(page + 1)
    }

    private func loadPage(_ targetPage: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchAlbums(
                page: targetPage,
                pageSize: pageSize,
                category: selectedCategory?.slug
            )
            if targetPage == 1 {
                albums = response.albums
            } else {
                albums.append(contentsOf: response.albums)
            }
            page = targetPage
            totalPages = response.totalPages ?? targetPage
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func applyFilters() async {
        await loadInitial()
    }

    private func loadCategories() async {
        do {
            let response = try await service.fetchAlbumCategories()
            categories = response.categories
        } catch {
            // ignore; categories optional
        }
    }
}
