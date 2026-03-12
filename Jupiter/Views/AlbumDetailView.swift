import SwiftUI

struct AlbumDetailView: View {
    let albumId: String
    let preview: AlbumListItem?

    @StateObject private var viewModel: AlbumDetailViewModel
    @StateObject private var likeViewModel: AlbumLikeViewModel
    @Namespace private var heroNamespace
    @State private var showUnlock = false
    @State private var selectedMediaForFullscreen: MediaItem? = nil
    @State private var animatedItemIds: Set<String> = []
    private let spacing: CGFloat = 6

    init(albumId: String, preview: AlbumListItem? = nil) {
        self.albumId = albumId
        self.preview = preview
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(albumId: albumId))
        _likeViewModel = StateObject(wrappedValue: AlbumLikeViewModel(albumId: albumId))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    headerSection
                        .padding(.horizontal, 12)
                        .padding(.top, 12)

                    if viewModel.media.isEmpty && viewModel.isLoading {
                        AlbumDetailSkeletonView(
                            width: proxy.size.width,
                            columnCount: columnCount(for: proxy.size.width),
                            spacing: spacing
                        )
                        .padding(.horizontal, 12)
                    } else if !viewModel.media.isEmpty {
                        let itemIndexMap = Dictionary(
                            uniqueKeysWithValues: viewModel.media.enumerated().map { ($1.id, $0) }
                        )

                        MasonryGrid(
                            items: viewModel.media,
                            width: proxy.size.width,
                            columnCount: viewModel.media.count == 1 ? 1 : columnCount(for: proxy.size.width),
                            spacing: spacing
                        ) { item in
                            Button {
                                selectedMediaForFullscreen = item
                            } label: {
                                thumbnailView(for: item)
                                    .opacity(animatedItemIds.contains(item.id) ? 1 : 0.01)
                                    .offset(y: animatedItemIds.contains(item.id) ? 0 : 14)
                                    .onAppear {
                                        animateCardIfNeeded(
                                            id: item.id,
                                            index: itemIndexMap[item.id] ?? 0
                                        )
                                    }
                                    .task {
                                        await viewModel.loadMoreIfNeeded(current: item)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(width: proxy.size.width, alignment: .leading)

                        if viewModel.isLoading && viewModel.canLoadMore {
                            AlbumDetailLoadMoreSkeleton(
                                columnCount: columnCount(for: proxy.size.width),
                                spacing: spacing
                            )
                            .padding(.horizontal, 12)
                            .padding(.top, 2)
                        } else if !viewModel.canLoadMore {
                            Text("没有更多了")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                    } else if viewModel.errorMessage == nil && !viewModel.requiresPassword {
                        AlbumDetailEmptyStateView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 96)
            }
            .refreshable {
                animatedItemIds.removeAll()
                await viewModel.loadInitial()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(.systemGray6).opacity(0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .navigationTitle(viewModel.album?.title ?? preview?.title ?? String(localized: "Album"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if let message = viewModel.errorMessage, viewModel.media.isEmpty {
                AlbumDetailErrorCard(message: message) {
                    Task { await viewModel.loadInitial() }
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            if viewModel.media.isEmpty && !viewModel.isLoading {
                animatedItemIds.removeAll()
                await viewModel.loadInitial()
            }
            await likeViewModel.load()
        }
        .onChange(of: viewModel.requiresPassword) { _, requires in
            showUnlock = requires
        }
        .sheet(isPresented: $showUnlock) {
            AlbumUnlockSheet { password in
                await viewModel.unlock(password: password)
            }
        }
        .fullScreenCover(item: $selectedMediaForFullscreen) { item in
            ZStack {
                Color.black.ignoresSafeArea()
                MediaZoomPagerView(
                    items: viewModel.media,
                    startId: item.id,
                    namespace: heroNamespace
                ) {
                    Task { await viewModel.loadNextPageIfPossible() }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            AlbumLikeFloatingButton(
                liked: likeViewModel.liked,
                isLoading: likeViewModel.isLoading,
                style: AppConfig.albumLikeButtonStyle
            ) {
                Task { await likeViewModel.toggle() }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 24)
        }
    }

    private func animateCardIfNeeded(id: String, index: Int) {
        guard !animatedItemIds.contains(id) else { return }
        let delay = min(Double(index) * 0.015, 0.22)
        withAnimation(.easeOut(duration: 0.36).delay(delay)) {
            animatedItemIds.insert(id)
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        if let description = viewModel.album?.description ?? preview?.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("“")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(Color.black.opacity(0.26))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(description)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .lineSpacing(4)
                    .foregroundStyle(Color.black.opacity(0.72))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.96),
                                Color(.systemGray6).opacity(0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
        }
    }

    private func columnCount(for width: CGFloat) -> Int {
        if width >= 900 { return 4 }
        if width >= 600 { return 3 }
        return 2
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

private struct AlbumLikeFloatingButton: View {
    let liked: Bool
    let isLoading: Bool
    let style: AlbumLikeButtonVisualStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(liked ? .pink : iconColor)
                }
            }
            .frame(width: 58, height: 58)
            .background(backgroundFill)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 14, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var backgroundFill: some ShapeStyle {
        switch style {
        case .solidWhite:
            return AnyShapeStyle(Color.white)
        case .frosted:
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    private var borderColor: Color {
        switch style {
        case .solidWhite:
            return Color.black.opacity(0.08)
        case .frosted:
            return Color.white.opacity(0.55)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .solidWhite:
            return Color.black.opacity(0.16)
        case .frosted:
            return Color.black.opacity(0.12)
        }
    }

    private var iconColor: Color {
        switch style {
        case .solidWhite:
            return Color.black.opacity(0.8)
        case .frosted:
            return Color.black.opacity(0.76)
        }
    }
}

private struct AlbumDetailSkeletonView: View {
    let width: CGFloat
    let columnCount: Int
    let spacing: CGFloat

    private let heights: [CGFloat] = [180, 240, 210, 260, 220, 190, 250, 205]

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: spacing),
            count: max(1, columnCount)
        )

        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<max(columnCount * 4, 8), id: \.self) { index in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.08))
                    .frame(height: heights[index % heights.count])
                    .redacted(reason: .placeholder)
            }
        }
        .frame(width: width - 24, alignment: .leading)
    }
}

private struct AlbumDetailLoadMoreSkeleton: View {
    let columnCount: Int
    let spacing: CGFloat

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(minimum: 0), spacing: spacing),
            count: max(1, columnCount)
        )
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(0..<max(columnCount, 2), id: \.self) { index in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(index == 0 ? 0.08 : 0.06))
                    .frame(height: index.isMultiple(of: 2) ? 188 : 220)
                    .redacted(reason: .placeholder)
            }
        }
    }
}

private struct AlbumDetailEmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("这个相册还没有照片")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AlbumDetailErrorCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.orange.opacity(0.85))

            Text("加载失败")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("重试", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}

private struct AlbumCommentsSection: View {
    @ObservedObject var viewModel: AlbumCommentsViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var url = ""
    @State private var content = ""
    @State private var replyingTo: AlbumComment? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.comments.isEmpty {
                Text("No comments yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(commentNodes) { node in
                    CommentThread(node: node, depth: 0) { comment in
                        replyingTo = comment
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Add a comment")
                    .font(.subheadline)

                if let replyingTo {
                    HStack(spacing: 8) {
                        Text("Replying to: \(replyingTo.authorName ?? String(localized: "Anonymous"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Cancel") {
                            self.replyingTo = nil
                        }
                        .font(.caption)
                    }
                }

                TextField("Nickname", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                TextField("Website (optional)", text: $url)
                    .textFieldStyle(.roundedBorder)
                TextEditor(text: $content)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator))
                    )

                Button(viewModel.isSubmitting ? String(localized: "Submitting...") : String(localized: "Submit comment")) {
                    Task {
                        await viewModel.submit(
                            name: name,
                            email: email,
                            url: url,
                            content: content,
                            parentId: replyingTo?.id
                        )
                        if viewModel.errorMessage == nil {
                            name = ""
                            email = ""
                            url = ""
                            content = ""
                            replyingTo = nil
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || email.isEmpty || content.isEmpty || viewModel.isSubmitting)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var commentNodes: [CommentNode] {
        buildTree(from: viewModel.comments)
    }

    private func buildTree(from comments: [AlbumComment]) -> [CommentNode] {
        var childrenMap: [String: [AlbumComment]] = [:]
        var roots: [AlbumComment] = []

        for comment in comments {
            if let parent = comment.parentId, !parent.isEmpty {
                childrenMap[parent, default: []].append(comment)
            } else {
                roots.append(comment)
            }
        }

        func buildNodes(_ list: [AlbumComment]) -> [CommentNode] {
            list.map { comment in
                let children = buildNodes(childrenMap[comment.id] ?? [])
                return CommentNode(comment: comment, children: children)
            }
        }

        return buildNodes(roots)
    }
}

private struct AlbumCommentsSheet: View {
    @ObservedObject var viewModel: AlbumCommentsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                AlbumCommentsSection(viewModel: viewModel)
                    .padding(16)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

private struct CommentNode: Identifiable {
    let comment: AlbumComment
    let children: [CommentNode]
    var id: String { comment.id }
}

private struct CommentThread: View {
    let node: CommentNode
    let depth: Int
    let onReply: (AlbumComment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CommentRow(comment: node.comment, depth: depth, onReply: onReply)
            ForEach(node.children) { child in
                CommentThread(node: child, depth: depth + 1, onReply: onReply)
            }
        }
    }
}

private struct CommentRow: View {
    let comment: AlbumComment
    let depth: Int
    let onReply: (AlbumComment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(comment.authorName ?? String(localized: "Anonymous"))
                    .font(.caption.bold())
                if let dateText = formatDate(comment.createdAt) {
                    Text(dateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let status = comment.status, status != "approved" {
                    Text("Pending review")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button("Reply") {
                    onReply(comment)
                }
                .font(.caption2)
            }
            Text(comment.content)
                .font(.caption)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.leading, min(CGFloat(depth) * 16, 48))
    }

    private func formatDate(_ value: String?) -> String? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        return value
    }
}

private struct AlbumUnlockSheet: View {
    let onSubmit: (String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Password required")) {
                    SecureField("Enter album password", text: $password)
                }
            }
            .navigationTitle("Unlock album")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? String(localized: "Processing...") : String(localized: "Unlock")) {
                        Task {
                            isSubmitting = true
                            await onSubmit(password)
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(password.isEmpty || isSubmitting)
                }
            }
        }
    }
}

struct AlbumDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumDetailView(albumId: "a_1", preview: AlbumListItem(
            id: "a_1",
            title: "Japan 2024",
            description: "Tokyo & Kyoto",
            coverMedia: AlbumCoverMedia(id: "m_1", url: "https://example.com", urlThumb: nil, urlMedium: nil),
            mediaCount: 88,
            likes: 10,
            slug: "japan-2024",
            isProtected: true,
            categories: nil,
            categoryIds: nil
        ))
    }
}
