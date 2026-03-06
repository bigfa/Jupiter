import SwiftUI

struct AlbumListView: View {
    @Binding var rootSelection: RootSection
    @StateObject private var viewModel = AlbumListViewModel()
    private let cardSpacing: CGFloat = 14
    private let horizontalPadding: CGFloat = 14

    private let columns = [
        GridItem(.flexible(), spacing: 14)
    ]

    init(rootSelection: Binding<RootSection> = .constant(.albums)) {
        _rootSelection = rootSelection
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: cardSpacing) {
                    if viewModel.isLoading && viewModel.albums.isEmpty {
                        AlbumListSkeletonView()
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, 14)
                    } else {
                        LazyVGrid(columns: columns, spacing: cardSpacing) {
                            ForEach(viewModel.albums) { album in
                                NavigationLink(value: album) {
                                    AlbumCard(album: album)
                                        .task {
                                            await viewModel.loadMoreIfNeeded(current: album)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 14)

                        if viewModel.isLoading && !viewModel.albums.isEmpty {
                            AlbumListLoadMoreSkeleton()
                                .padding(.horizontal, horizontalPadding)
                        } else if !viewModel.albums.isEmpty && !viewModel.canLoadMore {
                            Text("No more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 12)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadInitial()
            }
            .safeAreaInset(edge: .top) {
                AlbumCategoryBar(
                    categories: viewModel.categories,
                    selectedCategory: $viewModel.selectedCategory
                ) {
                    Task { await viewModel.applyFilters() }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    FloatingTabSwitcher(selection: $rootSelection)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .overlay {
                if let message = viewModel.errorMessage, viewModel.albums.isEmpty {
                    VStack(spacing: 8) {
                        Text("Failed to load")
                            .font(.headline)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await viewModel.loadInitial() }
                        }
                    }
                    .padding()
                }
            }
            .task {
                if viewModel.albums.isEmpty {
                    await viewModel.loadInitial()
                }
            }
            .navigationDestination(for: AlbumListItem.self) { album in
                AlbumDetailView(albumId: album.id, preview: album)
            }
        }
    }
}

private struct AlbumCategoryBar: View {
    let categories: [MediaCategoryItem]
    @Binding var selectedCategory: MediaCategoryItem?
    let onChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                CategoryTab(
                    title: "All",
                    selected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    onChange()
                }

                ForEach(categories) { category in
                    CategoryTab(
                        title: category.name,
                        selected: selectedCategory?.id == category.id
                    ) {
                        selectedCategory = category
                        onChange()
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct CategoryTab: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 28, weight: selected ? .bold : .regular, design: .serif))
                .tracking(0.3)
                .foregroundStyle(selected ? Color.black : Color.gray.opacity(0.45))
        }
    }
}

struct AlbumListView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumListView()
    }
}

private struct AlbumListSkeletonView: View {
    private let skeletonHeight: CGFloat = 236

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(height: skeletonHeight)
            }
        }
    }
}

private struct AlbumListLoadMoreSkeleton: View {
    private let skeletonHeight: CGFloat = 236

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemGray5))
                    .frame(height: skeletonHeight)
            }
        }
        .padding(.bottom, 12)
    }
}
