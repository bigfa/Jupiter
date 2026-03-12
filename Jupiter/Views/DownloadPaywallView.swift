import SwiftUI

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

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Mesh Gradient
                MeshBackgroundView()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        heroHeader
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 20)

                        featuresList
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 20)
                        
                        purchaseNotes
                            .opacity(animateItems ? 1 : 0)
                            .offset(y: animateItems ? 0 : 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 220)
                }
            }
            .navigationTitle("Premium Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary.opacity(0.5))
                            .font(.title2)
                    }
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 20)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Buy Once, Download Forever")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                
                Text("Save high-definition original images to your library")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 20) {
            featureRow(icon: "photo.badge.arrow.down.fill", title: "Original Quality", subtitle: "Download photos in their highest resolution")
            featureRow(icon: "clock.arrow.2.circlepath", title: "Lifetime Access", subtitle: "One-time purchase, no recurring fees")
            featureRow(icon: "iphone.radiowaves.left.and.right", title: "Sync Everywhere", subtitle: "Automatically sync status across all devices")
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(.headline)
                Text(LocalizedStringKey(subtitle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var purchaseNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                noteRow("Secured by Apple App Store")
                noteRow("Restore on any device with same Apple ID")
                noteRow("No ads or hidden tracking")
            }
        }
        .padding(.horizontal, 8)
    }

    private func noteRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.6))
            Text(LocalizedStringKey(text))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionArea: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Button {
                    Task { await purchaseTapped() }
                } label: {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(viewModel.isPurchased ? "Purchased" : viewModel.purchaseButtonTitle)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(viewModel.isPurchased ? Color.gray : Color.primary)
                    )
                    .foregroundStyle(viewModel.isPurchased ? .white.opacity(0.8) : (Color(.systemBackground)))
                }
                .disabled(viewModel.isProcessing || viewModel.isPurchased || viewModel.isLoading)
                
                Button {
                    Task { await restoreTapped() }
                } label: {
                    Text("Restore Purchase")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .disabled(viewModel.isProcessing || viewModel.isLoading)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            
            Text(viewModel.isPurchased ? "Download benefits unlocked" : "Download benefits locked")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [.clear, Color(.systemBackground).opacity(0.8), Color(.systemBackground)],
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

struct MeshBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
            
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: animate ? 100 : -100, y: animate ? -200 : -100)
            
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -150 : 50, y: animate ? 100 : 200)
            
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: animate ? 50 : 150, y: animate ? 200 : -50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

