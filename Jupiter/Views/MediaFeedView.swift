import SwiftUI

struct MediaFeedView: View {
    @Binding var rootSelection: RootSection
    @StateObject private var viewModel = MediaFeedViewModel()
    @Namespace private var heroNamespace
    @State private var selectedMediaForFullscreen: MediaItem? = nil

    private let spacing: CGFloat = 6

    init(rootSelection: Binding<RootSection> = .constant(.home)) {
        _rootSelection = rootSelection
    }

    var body: some View {
        ZStack {
            NavigationStack {
                GeometryReader { proxy in
                    let columnCountValue = columnCount(for: proxy.size.width)
                    let isHeatSorted = viewModel.selectedSort == .likes

                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                Color.clear
                                    .frame(height: 0)
                                    .id("top")

                                if viewModel.items.isEmpty && viewModel.isLoading {
                                    MediaFeedSkeletonView(
                                        spacing: spacing,
                                        columnCount: columnCountValue,
                                        horizontalPadding: spacing
                                    )
                                } else {
                                    if isHeatSorted {
                                        MasonryGrid(
                                            items: viewModel.items,
                                            width: proxy.size.width,
                                            columnCount: viewModel.items.count == 1 ? 1 : columnCountValue,
                                            spacing: spacing
                                        ) { item in
                                            Button {
                                                selectedMediaForFullscreen = item
                                            } label: {
                                                thumbnailView(for: item)
                                                    .task {
                                                        await viewModel.loadMoreIfNeeded(current: item)
                                                    }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .frame(width: proxy.size.width, alignment: .leading)
                                    } else {
                                        ForEach(buildSections(from: viewModel.items)) { section in
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(section.title)
                                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                                    .tracking(0.3)
                                                    .foregroundStyle(Color.black)
                                                    .padding(.top, 8)
                                                    .padding(.horizontal, spacing)

                                                MasonryGrid(
                                                    items: section.items,
                                                    width: proxy.size.width,
                                                    columnCount: section.items.count == 1 ? 1 : columnCountValue,
                                                    spacing: spacing
                                                ) { item in
                                                    Button {
                                                        selectedMediaForFullscreen = item
                                                    } label: {
                                                        thumbnailView(for: item)
                                                            .task {
                                                                await viewModel.loadMoreIfNeeded(current: item)
                                                            }
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                                .frame(width: proxy.size.width, alignment: .leading)
                                            }
                                        }
                                    }

                                    if viewModel.isLoading {
                                        MediaLoadMoreSkeleton(
                                            spacing: spacing,
                                            columnCount: columnCountValue
                                        )
                                        .frame(width: proxy.size.width, alignment: .leading)
                                    } else if !viewModel.items.isEmpty && !viewModel.canLoadMore {
                                        Text("没有更多了")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                }
                            }
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                        .onChange(of: viewModel.selectedSort) { _, _ in
                            scrollProxy.scrollTo("top", anchor: .top)
                        }
                        .onChange(of: viewModel.selectedCategory) { _, _ in
                            scrollProxy.scrollTo("top", anchor: .top)
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        MediaFilterBar(
                            categories: viewModel.categories,
                            selectedCategory: $viewModel.selectedCategory,
                            selectedSort: $viewModel.selectedSort
                        ) {
                            Task { await viewModel.applyFilters() }
                        }
                        .padding(.horizontal, spacing)
                        .padding(.top, spacing)
                        .padding(.bottom, 8)
                        .background(Color(.systemBackground))
                    }
                }
                .navigationTitle("")
                .overlay {
                    if viewModel.items.isEmpty && viewModel.errorMessage == nil && !viewModel.isLoading && viewModel.hasAttemptedInitialLoad {
                        EmptyCategoryPlaceholder(title: viewModel.selectedCategory?.name ?? "All")
                            .padding()
                    } else if let message = viewModel.errorMessage, viewModel.items.isEmpty {
                        VStack(spacing: 8) {
                            Text("加载失败")
                                .font(.headline)
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("重试") {
                                Task { await viewModel.loadInitial() }
                            }
                        }
                        .padding()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    ZStack {
                        FloatingTabSwitcher(selection: $rootSelection)

                        HStack {
                            SortFloatingButton(
                                selectedSort: viewModel.selectedSort,
                                onSelect: { option in
                                    viewModel.selectedSort = option
                                    Task { await viewModel.applyFilters() }
                                }
                            )
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .task {
                    if viewModel.items.isEmpty {
                        await viewModel.loadInitial(preserveItems: false)
                    }
                }
                .fullScreenCover(item: $selectedMediaForFullscreen) { item in
                    ZStack {
                        Color.black.ignoresSafeArea()
                        MediaZoomPagerView(
                            items: viewModel.items,
                            startId: item.id,
                            namespace: heroNamespace
                        ) {
                            Task { await viewModel.loadNextPageIfPossible() }
                        }
                    }
                }
            }
        }
    }

    private func columnCount(for width: CGFloat) -> Int {
        if width >= 900 { return 4 }
        if width >= 600 { return 3 }
        return 2
    }

    private func buildSections(from items: [MediaItem]) -> [MediaDaySection] {
        var sections: [MediaDaySection] = []
        var currentKey: String? = nil
        var currentTitle: String = ""
        var currentItems: [MediaItem] = []

        for item in items {
            let (key, title) = dateKeyTitle(for: item)
            if currentKey == nil {
                currentKey = key
                currentTitle = title
            }
            if key != currentKey {
                if let currentKey {
                    sections.append(MediaDaySection(id: currentKey, title: currentTitle, items: currentItems))
                }
                currentKey = key
                currentTitle = title
                currentItems = []
            }
            currentItems.append(item)
        }

        if let currentKey {
            sections.append(MediaDaySection(id: currentKey, title: currentTitle, items: currentItems))
        }

        return sections
    }

    private func dateKeyTitle(for item: MediaItem) -> (String, String) {
        let raw = item.datetimeOriginal ?? item.createdAt
        guard let raw, let date = parseISODate(raw) else {
            return ("unknown", "未知日期")
        }

        let keyFormatter = DateFormatter()
        keyFormatter.calendar = Calendar(identifier: .gregorian)
        keyFormatter.locale = Locale(identifier: "zh_CN")
        keyFormatter.dateFormat = "yyyy-MM-dd"
        let key = keyFormatter.string(from: date)

        let titleFormatter = DateFormatter()
        titleFormatter.calendar = Calendar(identifier: .gregorian)
        titleFormatter.locale = Locale(identifier: "en_US_POSIX")
        let currentYear = Calendar.current.component(.year, from: Date())
        let itemYear = Calendar.current.component(.year, from: date)
        if currentYear == itemYear {
            titleFormatter.dateFormat = "MMM dd"
        } else {
            titleFormatter.dateFormat = "MMM dd, yyyy"
        }
        let title = titleFormatter.string(from: date)

        return (key, title)
    }

    private func parseISODate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        if let date = isoFallback.date(from: value) {
            return date
        }

        // EXIF style: "2025:05:31 03:07:18"
        let exifFormatter = DateFormatter()
        exifFormatter.locale = Locale(identifier: "en_US_POSIX")
        exifFormatter.timeZone = TimeZone.current
        exifFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return exifFormatter.date(from: value)
    }

    @ViewBuilder
    private func thumbnailView(for item: MediaItem) -> some View {
        let card = MediaMasonryCard(item: item)
        if #available(iOS 18, *) {
            card.matchedTransitionSource(id: item.id, in: heroNamespace)
        } else {
            card
        }
    }
}

private struct MediaDaySection: Identifiable {
    let id: String
    let title: String
    let items: [MediaItem]
}

private struct MediaFeedSkeletonView: View {
    let spacing: CGFloat
    let columnCount: Int
    let horizontalPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<2, id: \.self) { _ in
                SkeletonLine(width: 140, height: 18)
                    .padding(.top, 8)
                    .padding(.horizontal, horizontalPadding)

                SkeletonMasonryGrid(
                    columnCount: columnCount,
                    spacing: spacing,
                    heights: [140, 200, 160, 220, 180, 150, 210, 170]
                )
            }
        }
    }
}

private struct MediaLoadMoreSkeleton: View {
    let spacing: CGFloat
    let columnCount: Int

    var body: some View {
        SkeletonMasonryGrid(
            columnCount: columnCount,
            spacing: spacing,
            heights: [140, 200, 160, 180]
        )
        .padding(.bottom, 12)
    }
}

private struct SkeletonMasonryGrid: View {
    let columnCount: Int
    let spacing: CGFloat
    let heights: [CGFloat]

    var body: some View {
        let columns = distributeHeights()

        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns.count, id: \.self) { index in
                LazyVStack(spacing: spacing) {
                    ForEach(columns[index].indices, id: \.self) { idx in
                        SkeletonBlock(height: columns[index][idx])
                    }
                }
            }
        }
    }

    private func distributeHeights() -> [[CGFloat]] {
        let count = max(1, columnCount)
        var columns = Array(repeating: [CGFloat](), count: count)
        var columnHeights = Array(repeating: CGFloat(0), count: count)

        for height in heights {
            let target = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            columns[target].append(height)
            columnHeights[target] += height + spacing
        }

        return columns
    }
}

private struct SkeletonBlock: View {
    let height: CGFloat
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                Color(.systemGray5)
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.35), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase * width * 1.5)
            }
        }
        .frame(height: height)
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

private struct SkeletonLine: View {
    let width: CGFloat
    let height: CGFloat
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            let actualWidth = min(width, geo.size.width)
            ZStack {
                Color(.systemGray5)
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.35), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase * actualWidth * 1.5)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

private struct MediaFilterBar: View {
    let categories: [MediaCategoryItem]
    @Binding var selectedCategory: MediaCategoryItem?
    @Binding var selectedSort: MediaSortOption
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
}

private struct SortFloatingButton: View {
    let selectedSort: MediaSortOption
    let onSelect: (MediaSortOption) -> Void

    @State private var showMenu = false

    var body: some View {
        FloatingCapsuleButton(action: { showMenu = true }) {
            Image(systemName: "line.3.horizontal.decrease.circle")
            Text(selectedSort.label)
        }
        .confirmationDialog("排序方式", isPresented: $showMenu, titleVisibility: .visible) {
            ForEach(MediaSortOption.allCases) { option in
                Button(option.label) {
                    onSelect(option)
                }
            }
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
        .buttonStyle(.plain)
    }
}

private struct EmptyCategoryPlaceholder: View {
    let title: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No photos in \(title)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MediaFeedView_Previews: PreviewProvider {
    static var previews: some View {
        MediaFeedView()
    }
}
