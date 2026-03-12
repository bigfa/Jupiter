import Foundation
import StoreKit
import Combine

enum DownloadPurchaseResult: Equatable {
    case purchased
    case pending
    case cancelled
    case failed(String)
}

enum DownloadRestoreResult: Equatable {
    case restored
    case nothingToRestore
    case failed(String)
}

@MainActor
final class DownloadAccessViewModel: ObservableObject {
    @Published private(set) var isPurchased = false
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published private(set) var priceText: String? = nil

    private let productId: String
    private var product: Product? = nil
    private var updatesTask: Task<Void, Never>? = nil

    init(productId: String? = nil) {
        self.productId = productId ?? AppConfig.downloadUnlockProductID
        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var purchaseButtonTitle: String {
        if let priceText {
            return "One-time purchase (\(priceText))"
        }
        return "One-time purchase"
    }

    var purchasedStatus: String {
        return "Purchased"
    }

    func prepare() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        await refreshEntitlement()
        await loadProduct()
    }

    func purchase() async -> DownloadPurchaseResult {
        if product == nil {
            await loadProduct()
        }
        guard let product else {
            return .failed("Purchase item unavailable")
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard let transaction = verifiedTransaction(from: verification) else {
                    return .failed("Purchase verification failed")
                }
                await transaction.finish()
                await refreshEntitlement()
                return isPurchased ? .purchased : .failed("Purchase not effective, please try again")
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed("Unknown purchase status")
            }
        } catch {
            return .failed("Purchase failed, please try again")
        }
    }

    func restore() async -> DownloadRestoreResult {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if isPurchased {
                return .restored
            }
            return .nothingToRestore
        } catch {
            return .failed("Restore failed, please try again")
        }
    }

    private func loadProduct() async {
        do {
            let products = try await Product.products(for: [productId])
            product = products.first
            priceText = product?.displayPrice
        } catch {
            product = nil
            priceText = nil
        }
    }

    private func refreshEntitlement() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = verifiedTransaction(from: result) else { continue }
            guard transaction.productID == productId else { continue }
            if transaction.revocationDate == nil {
                hasEntitlement = true
                break
            }
        }
        isPurchased = hasEntitlement
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard let transaction = verifiedTransaction(from: result) else { continue }
            guard transaction.productID == productId else { continue }
            await transaction.finish()
            await refreshEntitlement()
        }
    }

    private func verifiedTransaction(from result: VerificationResult<Transaction>) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            return nil
        }
    }
}
