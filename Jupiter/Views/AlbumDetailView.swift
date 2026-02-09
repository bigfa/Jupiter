import SwiftUI

struct AlbumDetailView: View {
    let albumId: String
    let preview: AlbumListItem?

    @StateObject private var viewModel: AlbumDetailViewModel
    @StateObject private var likeViewModel: AlbumLikeViewModel
    @StateObject private var commentsViewModel: AlbumCommentsViewModel
    @Namespace private var heroNamespace
    @State private var showUnlock = false
    @State private var showComments = false
    @State private var selectedMediaForFullscreen: MediaItem? = nil
    private let spacing: CGFloat = 6

    init(albumId: String, preview: AlbumListItem? = nil) {
        self.albumId = albumId
        self.preview = preview
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(albumId: albumId))
        _likeViewModel = StateObject(wrappedValue: AlbumLikeViewModel(albumId: albumId))
        _commentsViewModel = StateObject(wrappedValue: AlbumCommentsViewModel(albumId: albumId))
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerSection
                        .padding(.horizontal, 12)
                        .padding(.top, 12)

                    if !viewModel.media.isEmpty {
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
        }
        .navigationTitle("相册")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if viewModel.isLoading && viewModel.media.isEmpty {
                ProgressView()
            } else if let message = viewModel.errorMessage, viewModel.media.isEmpty {
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
        .task {
            if viewModel.media.isEmpty && !viewModel.isLoading {
                await viewModel.loadInitial()
            }
            await likeViewModel.load()
            await commentsViewModel.load()
        }
        .onChange(of: viewModel.requiresPassword) { _, requires in
            showUnlock = requires
        }
        .sheet(isPresented: $showUnlock) {
            AlbumUnlockSheet { password in
                await viewModel.unlock(password: password)
            }
        }
        .sheet(isPresented: $showComments) {
            AlbumCommentsSheet(viewModel: commentsViewModel)
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
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.album?.title ?? preview?.title ?? "相册")
                .font(.title2.bold())

            if let description = viewModel.album?.description ?? preview?.description, !description.isEmpty {
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if let count = viewModel.album?.mediaCount ?? preview?.mediaCount {
                    Text("\(count) 张")
                }
                if likeViewModel.likes > 0 {
                    Text("♥︎ \(likeViewModel.likes)")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    Task { await likeViewModel.toggle() }
                } label: {
                    Label(likeViewModel.liked ? "已赞" : "点赞", systemImage: likeViewModel.liked ? "heart.fill" : "heart")
                }
                .buttonStyle(.borderedProminent)
                .tint(likeViewModel.liked ? .pink : .accentColor)

                Button {
                    showComments = true
                } label: {
                    Image(systemName: "text.bubble")
                }
                .buttonStyle(.bordered)
            }
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

private struct AlbumCommentsSection: View {
    @ObservedObject var viewModel: AlbumCommentsViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var url = ""
    @State private var content = ""
    @State private var replyingTo: AlbumComment? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("评论")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.comments.isEmpty {
                Text("暂无评论")
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
                Text("发表评论")
                    .font(.subheadline)

                if let replyingTo {
                    HStack(spacing: 8) {
                        Text("回复: \(replyingTo.authorName ?? "匿名")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("取消") {
                            self.replyingTo = nil
                        }
                        .font(.caption)
                    }
                }

                TextField("昵称", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("邮箱", text: $email)
                    .textFieldStyle(.roundedBorder)
                TextField("网站（可选）", text: $url)
                    .textFieldStyle(.roundedBorder)
                TextEditor(text: $content)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator))
                    )

                Button(viewModel.isSubmitting ? "提交中..." : "提交评论") {
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
            .navigationTitle("评论")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
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
                Text(comment.authorName ?? "匿名")
                    .font(.caption.bold())
                if let dateText = formatDate(comment.createdAt) {
                    Text(dateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let status = comment.status, status != "approved" {
                    Text("审核中")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Button("回复") {
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
                Section(header: Text("需要密码")) {
                    SecureField("输入相册密码", text: $password)
                }
            }
            .navigationTitle("解锁相册")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "处理中" : "解锁") {
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
