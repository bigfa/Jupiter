import SwiftUI

struct AlbumListView: View {
    @Binding var rootSelection: RootSection
    @StateObject private var viewModel = AlbumListViewModel()
    private let cardSpacing: CGFloat = 14
    private let horizontalPadding: CGFloat = 16

    private let columns = [
        GridItem(.flexible(), spacing: 14)
    ]

    init(rootSelection: Binding<RootSection> = .constant(.albums)) {
        _rootSelection = rootSelection
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AlbumListBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: cardSpacing) {
                        if viewModel.isLoading && viewModel.albums.isEmpty {
                            AlbumListSkeletonView()
                                .padding(.horizontal, horizontalPadding)
                                .padding(.top, 14)
                        } else {
                            LazyVGrid(columns: columns, spacing: cardSpacing) {
                                ForEach(viewModel.albums) { album in
                                    NavigationLink {
                                        AlbumDetailView(albumId: album.id, preview: album)
                                    } label: {
                                        AlbumCard(album: album)
                                            .contentShape(Rectangle())
                                            .task {
                                                await viewModel.loadMoreIfNeeded(current: album)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .id(album.id)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, 14)

                            if viewModel.isLoading && !viewModel.albums.isEmpty {
                                AlbumListLoadMoreSkeleton()
                                    .padding(.horizontal, horizontalPadding)
                            } else if !viewModel.albums.isEmpty && !viewModel.canLoadMore {
                                Text("已经到底了")
                                    .font(.caption)
                                    .foregroundStyle(Color.black.opacity(0.42))
                                    .padding(.bottom, 12)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
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
                .background(CinematicToolbarBackground())
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
                    AlbumListMessageCard(
                        title: "相册加载失败",
                        summary: message,
                        actionTitle: "重新加载"
                    ) {
                        Task { await viewModel.loadInitial() }
                    }
                    .padding(.horizontal, 24)
                } else if !viewModel.isLoading && viewModel.albums.isEmpty {
                    AlbumListMessageCard(
                        title: "还没有相册",
                        summary: "等第一本相册出现后，这里会用更安静的方式把它们排好。",
                        actionTitle: "刷新看看"
                    ) {
                        Task { await viewModel.refresh() }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .task {
                if viewModel.albums.isEmpty {
                    await viewModel.loadInitial()
                }
            }
        }
    }
}

private struct AlbumListBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CinematicPalette.warmCanvas,
                    Color(red: 0.989, green: 0.979, blue: 0.964),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.91, green: 0.67, blue: 0.50).opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: animate ? 120 : 80, y: animate ? -220 : -180)

            Circle()
                .fill(Color(red: 0.86, green: 0.43, blue: 0.38).opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 42)
                .offset(x: animate ? -90 : -54, y: animate ? 240 : 190)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

private struct AlbumListMessageCard: View {
    let title: String
    let summary: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.black.opacity(0.86))

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.58))
                .lineSpacing(4)

            Button(actionTitle, action: action)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(CinematicPalette.warmCanvas)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(CinematicPalette.warmSurface.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
}

private struct AlbumCategoryBar: View {
    let categories: [MediaCategoryItem]
    @Binding var selectedCategory: MediaCategoryItem?
    let onChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryTab(
                    title: "全部",
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
            .padding(.vertical, 6)
        }
    }
}

private struct CategoryTab: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let style = CinematicSurfaceStyle.tab(selected: selected)
            Text(title)
                .font(.system(size: 18, weight: selected ? .semibold : .medium, design: .serif))
                .tracking(0.2)
                .foregroundStyle(CinematicPalette.chromeText.opacity(style.foregroundOpacity))
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .background(
                    Capsule(style: .continuous)
                        .fill(CinematicPalette.warmSurface.opacity(style.fillOpacity))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            CinematicPalette.chromeStroke.opacity(style.strokeOpacity),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: CinematicPalette.chromeShadow.opacity(style.shadowOpacity),
                    radius: style.shadowRadius,
                    x: 0,
                    y: selected ? 6 : 0
                )
        }
        .buttonStyle(.plain)
    }
}

struct AlbumListView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumListView()
    }
}

private struct AlbumListSkeletonView: View {
    private let skeletonHeight: CGFloat = 280

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(CinematicPalette.warmSurface.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .frame(height: skeletonHeight)
            }
        }
    }
}

private struct AlbumListLoadMoreSkeleton: View {
    private let skeletonHeight: CGFloat = 280

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<2, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(CinematicPalette.warmSurface.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .frame(height: skeletonHeight)
            }
        }
        .padding(.bottom, 12)
    }
}
