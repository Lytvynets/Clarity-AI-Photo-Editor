

import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {

    enum PurchaseOutcome {
        case success
        case cancelled
        case pending
        case failed(String)
    }

    @Published private(set) var isPro: Bool
    /// True while the active subscription is still inside its free introductory trial.
    @Published private(set) var isTrial: Bool
    @Published private(set) var products: [Product] = []
    @Published private(set) var trialEligible = false
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false

    private let cacheKey = "pro.cached.v2"
    private let trialCacheKey = "pro.trial.v1"
    private var updatesTask: Task<Void, Never>?

    init() {
        let cachedPro = UserDefaults.standard.bool(forKey: cacheKey)
        isPro = cachedPro
        isTrial = cachedPro && UserDefaults.standard.bool(forKey: trialCacheKey)
        AppAnalytics.plan = Self.planName(pro: cachedPro, trial: isTrial)
        updatesTask = listenForTransactions()
        Task { await self.refresh() }
    }


    func product(_ id: String) -> Product? {
        products.first { $0.id == id }
    }

    /// Daily fair-use budget for the current subscription state.
    var proDailyLimit: Int { isTrial ? Limits.trialDailyUnits : Limits.proDailyUnits }

    var yearly: Product? { product(ProductID.yearly) }
    var monthly: Product? { product(ProductID.monthly) }

    var weekly: Product? {
        if trialEligible, let trial = product(ProductID.weeklyTrial) { return trial }
        return product(ProductID.weekly) ?? product(ProductID.weeklyTrial)
    }

    func perWeekPrice(of product: Product, weeks: Decimal) -> String {
        (product.price / weeks).formatted(product.priceFormatStyle)
    }

    var yearlySavingsPercent: Int? {
        guard let yearly, let weeklyProduct = product(ProductID.weekly) ?? product(ProductID.weeklyTrial) else { return nil }
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        let weeklyPrice = NSDecimalNumber(decimal: weeklyProduct.price).doubleValue * 52
        guard weeklyPrice > 0, yearlyPrice < weeklyPrice else { return nil }
        return Int(((1 - yearlyPrice / weeklyPrice) * 100).rounded())
    }


    func refresh() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let fetched = try await Product.products(for: ProductID.all)
            products = fetched
            if let trial = fetched.first(where: { $0.id == ProductID.weeklyTrial }),
               let info = trial.subscription,
               info.introductoryOffer != nil {
                trialEligible = await info.isEligibleForIntroOffer
            } else {
                trialEligible = false
            }
        } catch {
            print("⚠️ Could not load products: \(error)")
        }
    }

    func refreshEntitlements() async {
        var active = false
        var inTrial = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard ProductID.all.contains(transaction.productID) else { continue }
            if transaction.revocationDate != nil { continue }
            if let expiration = transaction.expirationDate, expiration < Date() { continue }
            active = true
            if transaction.offerType == .introductory { inTrial = true }
        }
        setPro(active, trial: active && inTrial)
    }

    private func setPro(_ value: Bool, trial: Bool = false) {
        if isPro != value { isPro = value }
        if isTrial != trial { isTrial = trial }
        UserDefaults.standard.set(value, forKey: cacheKey)
        UserDefaults.standard.set(trial, forKey: trialCacheKey)
        AppAnalytics.plan = Self.planName(pro: value, trial: trial)
    }

    private static func planName(pro: Bool, trial: Bool) -> String {
        if !pro { return "free" }
        return trial ? "trial" : "pro"
    }


    func purchase(_ product: Product) async -> PurchaseOutcome {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    setPro(true, trial: transaction.offerType == .introductory)
                    await refreshEntitlements()
                    return .success
                case .unverified:
                    return .failed("The purchase could not be verified. Please try again.")
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("Something went wrong. Please try again.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restore() async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
        } catch {
            print("⚠️ Restore failed: \(error)")
        }
        await refreshEntitlements()
        return isPro
    }


    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                guard let self else { return }
                await self.refreshEntitlements()
            }
        }
    }
}
