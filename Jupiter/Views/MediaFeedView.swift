import SwiftUI
import SafariServices

struct MediaFeedView: View {
    @Binding var rootSelection: RootSection
    @StateObject private var viewModel = MediaFeedViewModel()
    @Namespace private var heroNamespace
    @State private var selectedMediaForFullscreen: MediaItem? = nil
    @State private var showAppInfo = false

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
                                        Text("No more")
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
                        .background(CinematicToolbarBackground())
                    }
                }
                .navigationTitle("")
                .overlay {
                    if viewModel.items.isEmpty && viewModel.errorMessage == nil && !viewModel.isLoading && viewModel.hasAttemptedInitialLoad {
                        EmptyCategoryPlaceholder(title: viewModel.selectedCategory?.name ?? String(localized: "All"))
                            .padding()
                    } else if let message = viewModel.errorMessage, viewModel.items.isEmpty {
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
                            SettingsFloatingButton { showAppInfo = true }
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
                .sheet(isPresented: $showAppInfo) {
                    AppInfoSheet()
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
            return ("unknown", String(localized: "Unknown date"))
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
                        title: LocalizedStringKey("All"),
                        selected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                        onChange()
                    }

                    ForEach(categories) { category in
                        CategoryTab(
                            title: LocalizedStringKey(category.name),
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
        .confirmationDialog(Text("Sort"), isPresented: $showMenu, titleVisibility: .visible) {
            ForEach(MediaSortOption.allCases) { option in
                Button(option.label) {
                    onSelect(option)
                }
            }
        }
    }
}

private struct CategoryTab: View {
    let title: LocalizedStringKey
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let style = CinematicSurfaceStyle.tab(selected: selected)
            Text(title)
                .font(.system(size: 28, weight: selected ? .bold : .regular, design: .serif))
                .tracking(0.3)
                .foregroundStyle(CinematicPalette.chromeText.opacity(style.foregroundOpacity))
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

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

private struct SettingsFloatingButton: View {
    let action: () -> Void

    var body: some View {
        FloatingCapsuleButton(action: action) {
            Image(systemName: "gearshape")
        }
    }
}

struct AppInfoHeroContent: Equatable {
    let eyebrow: String
    let title: String
    let summary: String
    let versionLabel: String
    let highlights: [String]
}

struct AppInfoAccessCardContent: Equatable {
    let title: String
    let status: String
    let summary: String
    let actionTitle: String
    let isUnlocked: Bool
}

struct AppInfoPrimaryCardContent: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
}

enum AppInfoPresentation {
    static func hero(version: String) -> AppInfoHeroContent {
        AppInfoHeroContent(
            eyebrow: "关于产品",
            title: "Tinyglim",
            summary: "把照片、相册和下载权益收在一张更安静、更轻盈的画布里。",
            versionLabel: "版本 \(version)",
            highlights: ["照片浏览", "相册整理", "原图下载"]
        )
    }

    static func accessCard(isPurchased: Bool) -> AppInfoAccessCardContent {
        if isPurchased {
            return AppInfoAccessCardContent(
                title: "下载权益",
                status: "已解锁",
                summary: "原图下载与 HDR 照片显示已可用，可直接进入查看权益详情。",
                actionTitle: "查看详情",
                isUnlocked: true
            )
        }

        return AppInfoAccessCardContent(
            title: "下载权益",
            status: "未解锁",
            summary: "一次购买后即可永久下载原图，并解锁 HDR 照片显示。",
            actionTitle: "查看权益",
            isUnlocked: false
        )
    }

    static func primaryCards() -> [AppInfoPrimaryCardContent] {
        [
            AppInfoPrimaryCardContent(
                id: "contact",
                title: "联系作者",
                subtitle: "反馈问题、合作沟通，或者只是打个招呼。",
                systemImage: "envelope.badge"
            ),
            AppInfoPrimaryCardContent(
                id: "privacy",
                title: "隐私政策",
                subtitle: "查看应用如何处理数据与下载权益相关信息。",
                systemImage: "hand.raised"
            ),
            AppInfoPrimaryCardContent(
                id: "terms",
                title: "服务条款",
                subtitle: "查看服务说明、购买与使用相关约定。",
                systemImage: "doc.text"
            )
        ]
    }
}

private struct AppInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var safariURL: URL? = nil
    @State private var showPaywall = false
    @State private var animateSections = false
    @StateObject private var downloadAccessViewModel = DownloadAccessViewModel()

    private let privacyURL = URL(string: "https://tinyglim.wpista.com/legal.html")!
    private let termsURL = URL(string: "https://tinyglim.wpista.com/legal.html#terms")!
    private let authorEmailURL = URL(string: "mailto:jigoulee@gmail.com")!

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return version
    }

    private var heroContent: AppInfoHeroContent {
        AppInfoPresentation.hero(version: appVersion)
    }

    private var accessContent: AppInfoAccessCardContent {
        AppInfoPresentation.accessCard(isPurchased: downloadAccessViewModel.isPurchased)
    }

    private var primaryCards: [AppInfoPrimaryCardContent] {
        AppInfoPresentation.primaryCards()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppInfoBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroSection
                            .opacity(animateSections ? 1 : 0)
                            .offset(y: animateSections ? 0 : 14)

                        accessSection
                            .opacity(animateSections ? 1 : 0)
                            .offset(y: animateSections ? 0 : 18)

                        actionsSection
                            .opacity(animateSections ? 1 : 0)
                            .offset(y: animateSections ? 0 : 22)

                        footerSection
                            .opacity(animateSections ? 1 : 0)
                            .offset(y: animateSections ? 0 : 26)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("关于 Tinyglim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPaywall) {
            DownloadPaywallView(viewModel: downloadAccessViewModel)
        }
        .task {
            await downloadAccessViewModel.prepare()
            withAnimation(.easeOut(duration: 0.55)) {
                animateSections = true
            }
        }
    }

    private var heroSection: some View {
        AppInfoSurface {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.90, green: 0.43, blue: 0.35),
                                        Color(red: 0.83, green: 0.56, blue: 0.36)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 62, height: 62)

                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.96))
                    }

                    Spacer(minLength: 12)

                    Text(heroContent.versionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.58))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(CinematicPalette.warmCanvas)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(heroContent.eyebrow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.48))
                        .tracking(0.6)

                    Text(heroContent.title)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.88))

                    Text(heroContent.summary)
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.62))
                        .lineSpacing(4)
                }

                HStack(spacing: 8) {
                    ForEach(heroContent.highlights, id: \.self) { item in
                        Text(item)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.black.opacity(0.68))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.76))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    private var accessSection: some View {
        Button {
            showPaywall = true
        } label: {
            AppInfoSurface {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(accessContent.title)
                                .font(.headline)
                                .foregroundStyle(Color.black.opacity(0.88))

                            Text(accessContent.summary)
                                .font(.subheadline)
                                .foregroundStyle(Color.black.opacity(0.62))
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 12)

                        Text(accessContent.status)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accessContent.isUnlocked ? Color.green.opacity(0.9) : Color(red: 0.79, green: 0.47, blue: 0.17))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(accessContent.isUnlocked ? Color.green.opacity(0.12) : Color(red: 0.97, green: 0.90, blue: 0.79))
                            )
                    }

                    if let priceText = downloadAccessViewModel.priceText, !downloadAccessViewModel.isPurchased {
                        Text("当前为一次性购买，价格 \(priceText)。")
                            .font(.caption)
                            .foregroundStyle(Color.black.opacity(0.5))
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.72))

                        Text(accessContent.actionTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.82))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.black.opacity(0.32))
                    }
                    .padding(.top, 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var actionsSection: some View {
        AppInfoSurface {
            VStack(spacing: 0) {
                ForEach(Array(primaryCards.enumerated()), id: \.element.id) { index, card in
                    Button {
                        handleTap(for: card)
                    } label: {
                        HStack(alignment: .center, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(CinematicPalette.warmCanvas)
                                    .frame(width: 42, height: 42)

                                Image(systemName: card.systemImage)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.black.opacity(0.68))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.black.opacity(0.84))

                                Text(card.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(Color.black.opacity(0.54))
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 12)

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.black.opacity(0.24))
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if index < primaryCards.count - 1 {
                        Divider()
                            .overlay(Color.black.opacity(0.06))
                    }
                }
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("Tinyglim 希望把照片体验做得更轻一点，也更安静一点。")
                .font(.footnote)
                .foregroundStyle(Color.black.opacity(0.5))
                .multilineTextAlignment(.center)

            Text("如需反馈或合作，可直接通过邮件联系。")
                .font(.caption)
                .foregroundStyle(Color.black.opacity(0.38))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
    }

    private func handleTap(for card: AppInfoPrimaryCardContent) {
        switch card.id {
        case "contact":
            openURL(authorEmailURL)
        case "privacy":
            safariURL = privacyURL
        case "terms":
            safariURL = termsURL
        default:
            break
        }
    }
}

private struct AppInfoBackground: View {
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
                .fill(Color(red: 0.91, green: 0.67, blue: 0.50).opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 32)
                .offset(x: animate ? 120 : 86, y: animate ? -220 : -180)

            Circle()
                .fill(Color(red: 0.86, green: 0.43, blue: 0.38).opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: animate ? -110 : -70, y: animate ? 220 : 180)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

private struct AppInfoSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
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

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct MediaFeedView_Previews: PreviewProvider {
    static var previews: some View {
        MediaFeedView()
    }
}
