import SwiftUI

struct DownloadPaywallView: View {
    @ObservedObject var viewModel: DownloadAccessViewModel
    let onUnlocked: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var message: String? = nil
    @State private var showMessageAlert = false

    init(viewModel: DownloadAccessViewModel, onUnlocked: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onUnlocked = onUnlocked
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(.systemGray6).opacity(0.82),
                        Color(.systemGray5).opacity(0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        heroCard
                        highlightsCard
                        trustCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 220)
                }
            }
            .navigationTitle("下载权益")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionDock
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.88),
                                Color.white
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
            }
        }
        .task {
            await viewModel.prepare()
        }
        .alert("购买提示", isPresented: $showMessageAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.black.opacity(0.76))
                VStack(alignment: .leading, spacing: 2) {
                    Text("一次购买，永久下载")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                    Text("高清原图保存到系统相册")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("你在任意入口解锁后，设置页和图片详情页都会自动同步权益状态。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color(.systemGray6).opacity(0.7)
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
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("解锁内容")
                .font(.headline)

            paywallItem(icon: "checkmark.circle.fill", text: "下载原图到系统相册")
            paywallItem(icon: "checkmark.circle.fill", text: "支持恢复购买记录")
            paywallItem(icon: "checkmark.circle.fill", text: "一次性买断，无自动续费")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var trustCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("购买说明")
                .font(.headline)
            paywallItem(icon: "shield.checkered", text: "购买由 Apple 完成结算与校验")
            paywallItem(icon: "person.crop.circle.badge.checkmark", text: "同一 Apple 账号可恢复购买")
            paywallItem(icon: "hand.raised.fill", text: "无广告、无订阅、无额外跟踪")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var actionDock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    viewModel.isPurchased ? "已解锁下载权益" : "尚未解锁下载权益",
                    systemImage: viewModel.isPurchased ? "checkmark.seal.fill" : "lock.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(viewModel.isPurchased ? .green : .secondary)
                Spacer()
            }

            Button {
                Task { await purchaseTapped() }
            } label: {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(viewModel.isPurchased ? "已购买" : viewModel.purchaseButtonTitle)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
                .buttonStyle(.borderedProminent)
            .disabled(viewModel.isProcessing || viewModel.isPurchased || viewModel.isLoading)

            Button("恢复购买") {
                Task { await restoreTapped() }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isProcessing || viewModel.isLoading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.75), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    private func paywallItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.black.opacity(0.72))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    @MainActor
    private func purchaseTapped() async {
        let result = await viewModel.purchase()
        switch result {
        case .purchased:
            onUnlocked?()
            dismiss()
        case .pending:
            presentMessage("购买处理中，请稍后在本页重试。")
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
            presentMessage("未找到可恢复的购买记录。")
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
