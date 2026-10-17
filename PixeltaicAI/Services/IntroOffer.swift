import Foundation
import StoreKit

/// How a subscription's introductory offer is described on the paywall.
///
/// Everything is read from what is set up in App Store Connect (a free trial, a discounted first
/// week, ...), so the texts always match the terms Apple shows in its purchase sheet and an offer
/// can be changed there without touching the app.
struct IntroOffer {
    /// "free" or "paid" (analytics).
    let kind: String
    let isFree: Bool
    /// Short label on the plan row, e.g. "3 DAYS FREE".
    let badge: String
    /// The main button, e.g. "Start free trial".
    let cta: String
    /// Second line of the plan row.
    let detail: String
    /// The fine print under the button.
    let disclosure: String

    static func make(for product: Product, period: String) -> IntroOffer? {
        guard let info = product.subscription, let offer = info.introductoryOffer else { return nil }

        let unit = word(offer.period.unit)
        let perPeriod = max(1, offer.period.value)
        let total = perPeriod * max(1, offer.periodCount)
        let renewal = "\(product.displayPrice) per \(period)"
        let runs = Limits.trialTotalUnits

        if offer.paymentMode == .freeTrial {
            let plural = total == 1 ? unit : unit + "s"
            return IntroOffer(
                kind: "free",
                isFree: true,
                badge: "\(total) \(plural.uppercased()) FREE",
                cta: "Start free trial",
                detail: "Try free, then \(renewal)",
                disclosure: "\(total)-\(unit) free trial with up to \(runs) runs, then \(renewal). Cancel anytime in Settings."
            )
        }

        let price = offer.displayPrice
        let first = total == 1 ? "first \(unit)" : "first \(total) \(unit)s"
        let perEach = perPeriod == 1 ? unit : "\(perPeriod) \(unit)s"
        // Pay as you go over several periods charges the price every period; otherwise it is one payment.
        let repeating = offer.paymentMode == .payAsYouGo && offer.periodCount > 1
        let terms = repeating ? "\(price) per \(perEach) for the \(first)" : "\(price) for the \(first)"
        let firstTitle = "First" + String(first.dropFirst(5))
        let shortDetail = repeating ? "\(price) per \(perEach), then \(product.displayPrice)"
                                    : "\(firstTitle) \(price), then \(product.displayPrice)"

        return IntroOffer(
            kind: "paid",
            isFree: false,
            badge: "TRY FOR \(price)",
            cta: "Try Pro for \(price)",
            detail: shortDetail,
            disclosure: "\(terms) with up to \(runs) runs, then \(renewal). Renews automatically until cancelled."
        )
    }

    private static func word(_ unit: Product.SubscriptionPeriod.Unit) -> String {
        if unit == .day { return "day" }
        if unit == .week { return "week" }
        if unit == .month { return "month" }
        if unit == .year { return "year" }
        return "period"
    }
}
