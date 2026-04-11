import SwiftUI

struct DownloadPaywallFeatureItem: Identifiable, Equatable {
    let id: String
    let systemImage: String
    let title: String
    let subtitle: String
}

enum DownloadPaywallPresentation {
    static func featureItems() -> [DownloadPaywallFeatureItem] {
        [
            DownloadPaywallFeatureItem(
                id: "original",
                systemImage: "photo.badge.arrow.down",
                title: "原图下载",
                subtitle: "以原始分辨率保存照片，不压缩重要细节。"
            ),
            DownloadPaywallFeatureItem(
                id: "hdr",
                systemImage: "sparkles",
                title: "HDR 显示",
                subtitle: "在支持的设备上查看更丰富的高光和层次。"
            ),
            DownloadPaywallFeatureItem(
                id: "lifetime",
                systemImage: "checkmark.seal",
                title: "一次购买",
                subtitle: "没有订阅压力，解锁后可长期使用下载权益。"
            ),
            DownloadPaywallFeatureItem(
                id: "restore",
                systemImage: "arrow.triangle.2.circlepath",
                title: "多设备恢复",
                subtitle: "同一 Apple ID 下可快速恢复已购买状态。"
            )
        ]
    }

    static func noteItems() -> [String] {
        [
            "由 Apple App Store 安全支付",
            "同一 Apple ID 可恢复购买",
            "不会加入广告或隐藏追踪"
        ]
    }

    static func statusBadge(isPurchased: Bool) -> String {
        isPurchased ? "已解锁" : "未解锁"
    }

    static func heroTitle(isPurchased: Bool) -> String {
        isPurchased ? "下载权益已可使用" : "解锁下载权益"
    }

    static func heroSummary(isPurchased: Bool) -> String {
        if isPurchased {
            return "原图下载与 HDR 显示已经可用，你可以继续浏览并随时保存照片。"
        }
        return "把喜欢的照片保存到你的相册里，同时解锁更完整的显示体验。"
    }

    static func footerCaption(isPurchased: Bool) -> String {
        isPurchased ? "当前账号已拥有下载权益" : "当前账号尚未解锁下载权益"
    }
}

struct DownloadPaywallView: View {
    @ObservedObject var viewModel: DownloadAccessViewModel
    let onUnlocked: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var message: String? = nil
    @State private var showMessageAlert = false
    @State private var animateItems = false

    init(viewModel: DownloadAccessViewModel, onUnlocked: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onUnlocked = onUnlocked
    }

    private var featureItems: [DownloadPaywallFeatureItem] {
        DownloadPaywallPresentation.featureItems()
    }

    private var noteItems: [String] {
        DownloadPaywallPresentation.noteItems()
    }

    private var statusBadge: String {
        DownloadPaywallPresentation.statusBadge(isPurchased: viewModel.isPurchased)
    }

    private var purchaseButtonFill: AnyShapeStyle {
        if viewModel.isPurchased {
            return AnyShapeStyle(Color(red: 0.76, green: 0.74, blue: 0.70))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.42, blue: 0.34),
                    Color(red: 0.82, green: 0.55, blue: 0.34)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CinematicPaywallBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroHeader
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 14)

                        featureSection
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 18)

                        noteSection
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 22)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 220)
                }
            }
            .navigationTitle("下载权益")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionArea
            }
        }
        .task {
            await viewModel.prepare()
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateItems = true
            }
        }
        .alert("Purchase Info", isPresented: $showMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private var heroHeader: some View {
        PaywallSurface {
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
                            .frame(width: 68, height: 68)

                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.96))
                    }

                    Spacer(minLength: 12)

                    Text(statusBadge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            viewModel.isPurchased
                            ? Color.green.opacity(0.9)
                            : Color(red: 0.79, green: 0.47, blue: 0.17)
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(
                                    viewModel.isPurchased
                                    ? Color.green.opacity(0.12)
                                    : Color(red: 0.97, green: 0.90, blue: 0.79)
                                )
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("下载与显示")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.48))
                        .tracking(0.6)

                    Text(DownloadPaywallPresentation.heroTitle(isPurchased: viewModel.isPurchased))
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(Color.black.opacity(0.88))

                    Text(DownloadPaywallPresentation.heroSummary(isPurchased: viewModel.isPurchased))
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.62))
                        .lineSpacing(4)
                }

                if !viewModel.isPurchased, let priceText = viewModel.priceText {
                    Text("一次购买 \(priceText)，立即解锁全部下载权益。")
                        .font(.caption)
                        .foregroundStyle(Color.black.opacity(0.52))
                }
            }
        }
    }

    private var featureSection: some View {
        PaywallSurface {
            VStack(alignment: .leading, spacing: 18) {
                Text("你会得到什么")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.84))

                VStack(spacing: 16) {
                    ForEach(featureItems) { item in
                        featureRow(item: item)
                    }
                }
            }
        }
    }

    private func featureRow(item: DownloadPaywallFeatureItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(CinematicPalette.warmCanvas)
                    .frame(width: 44, height: 44)

                Image(systemName: item.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.84))

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.56))
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
    }

    private var noteSection: some View {
        PaywallSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("购买说明")
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.84))

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(noteItems, id: \.self) { item in
                        noteRow(item)
                    }
                }
            }
        }
    }

    private func noteRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.caption)
                .foregroundStyle(Color.black.opacity(0.42))
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.black.opacity(0.56))
        }
    }

    private var actionArea: some View {
        VStack(spacing: 16) {
            PaywallSurface {
                VStack(spacing: 12) {
                    Button {
                        Task { await purchaseTapped() }
                    } label: {
                        HStack {
                            if viewModel.isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(viewModel.isPurchased ? "已解锁" : viewModel.purchaseButtonTitle)
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(purchaseButtonFill)
                        )
                        .foregroundStyle(Color.white.opacity(viewModel.isPurchased ? 0.82 : 0.96))
                    }
                    .disabled(viewModel.isProcessing || viewModel.isPurchased || viewModel.isLoading)

                    Button {
                        Task { await restoreTapped() }
                    } label: {
                        Text("恢复购买")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.black.opacity(0.56))
                    }
                    .disabled(viewModel.isProcessing || viewModel.isLoading)
                }
            }

            Text(DownloadPaywallPresentation.footerCaption(isPurchased: viewModel.isPurchased))
                .font(.caption2)
                .foregroundStyle(Color.black.opacity(0.46))
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    .clear,
                    CinematicPalette.warmCanvas.opacity(0.86),
                    CinematicPalette.warmCanvas
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    @MainActor
    private func purchaseTapped() async {
        let result = await viewModel.purchase()
        switch result {
        case .purchased:
            onUnlocked?()
            dismiss()
        case .pending:
            presentMessage("Purchase is processing, please try again on this page later.")
        case .cancelled:
            break
        case .failed(let error):
            presentMessage(error)
        }
    }

    @MainActor
    private func restoreTapped() async {
        let result = await viewModel.restore()
        switch result {
        case .restored:
            onUnlocked?()
            dismiss()
        case .nothingToRestore:
            presentMessage("No purchase history found.")
        case .failed(let error):
            presentMessage(error)
        }
    }

    @MainActor
    private func presentMessage(_ text: String) {
        message = text
        showMessageAlert = true
    }
}

private struct CinematicPaywallBackground: View {
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
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: animate ? 110 : 76, y: animate ? -220 : -170)

            Circle()
                .fill(Color(red: 0.86, green: 0.43, blue: 0.38).opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 42)
                .offset(x: animate ? -110 : -60, y: animate ? 200 : 160)

            Circle()
                .fill(Color(red: 0.89, green: 0.80, blue: 0.62).opacity(0.14))
                .frame(width: 200, height: 200)
                .blur(radius: 34)
                .offset(x: animate ? 24 : 70, y: animate ? 260 : 210)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

private struct PaywallSurface<Content: View>: View {
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
