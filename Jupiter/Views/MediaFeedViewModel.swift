import Foundation
import Combine

@MainActor
final class MediaFeedViewModel: ObservableObject {
    @Published private(set) var items: [MediaItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var categories: [MediaCategoryItem] = []
    @Published private(set) var hasAttemptedInitialLoad = false
    @Published var selectedCategory: MediaCategoryItem? = nil
    @Published var selectedSort: MediaSortOption = .date

    private let service = MediaService()
    private var page = 1
    private var totalPages = 1
    private let pageSize = 20

    var canLoadMore: Bool {
        page < totalPages && !isLoading
    }

    func loadInitial(preserveItems: Bool = false) async {
        errorMessage = nil
        page = 1
        totalPages = 1
        if !preserveItems {
            items = []
        }
        if categories.isEmpty {
            await loadCategories()
        }
        await loadPage(page)
        hasAttemptedInitialLoad = true
    }

    func loadMoreIfNeeded(current item: MediaItem) async {
        guard let last = items.last, last.id == item.id else { return }
        guard canLoadMore else { return }
        await loadPage(page + 1)
    }

    func loadNextPageIfPossible() async {
        guard canLoadMore else { return }
        await loadPage(page + 1)
    }

    private func loadPage(_ targetPage: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchMedia(
                page: targetPage,
                pageSize: pageSize,
                category: selectedCategory?.slug,
                sort: selectedSort.rawValue
            )
            if targetPage == 1 {
                items = response.results
            } else {
                items.append(contentsOf: response.results)
            }
            page = response.page
            totalPages = response.totalPages
        } catch {
            if Task.isCancelled {
                isLoading = false
                return
            }
            if let urlError = error as? URLError, urlError.code == .cancelled {
                isLoading = false
                return
            }
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func applyFilters() async {
        await loadInitial(preserveItems: false)
    }

    func refresh() async {
        guard !isRefreshing else { return }
        errorMessage = nil
        isRefreshing = true

        let category = selectedCategory?.slug
        let sort = selectedSort.rawValue
        let fetchService = service
        let fetchPageSize = pageSize

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Task.detached {
                defer { continuation.resume() }
                do {
                    let response = try await fetchService.fetchMedia(
                        page: 1,
                        pageSize: fetchPageSize,
                        category: category,
                        sort: sort
                    )
                    await MainActor.run { [weak self] in
                        self?.items = response.results
                        self?.page = response.page
                        self?.totalPages = response.totalPages
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }

        isRefreshing = false
    }

    private func loadCategories() async {
        do {
            let response = try await service.fetchCategories()
            categories = response.categories
        } catch {
            // ignore; categories optional
        }
    }
}
