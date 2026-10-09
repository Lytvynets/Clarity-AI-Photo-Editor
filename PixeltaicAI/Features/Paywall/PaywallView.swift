

import SwiftUI
import StoreKit

struct PaywallView: View {

    /// Where the paywall was opened from (analytics only).
    let placement: String

    init(placement: String = "other") {
        self.placement = placement
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscription: SubscriptionManager

    @State private var selectedID: String = ProductID.yearly
    @State private var glow = false
    @State private var breathe = false
    @State private var appeared = false
    @State private var alertText: String?
    @State private var loggedView = false

    /// The content is laid out at two densities. The roomy one is used when the screen is tall
    /// enough; smaller screens get the compact one. The page always scrolls, so on a very small
    /// screen or with a large system font nothing is ever out of reach.
    private static let regularLayoutMinHeight: CGFloat = 560

    private enum Density {
        case regular
        case compact

        var isCompact: Bool { self == .compact }
    }

    private var limitsFeature: String {
        let free = max(1, FreeTier.dailyRunUnits)
        let ratio = Limits.proDailyUnits / free
        return ratio >= 2 ? "\(ratio)× more edits every day" : "Higher daily limits"
    }

    private var features: [(symbol: String, text: String)] {
        [
            ("nosign", "No ads, ever"),
            ("arrow.up.left.and.arrow.down.right", "4× AI upscale"),
            ("bolt.fill", limitsFeature),
            ("square.grid.2x2.fill", "Up to 4 images per prompt"),
            ("checkmark.seal.fill", "Clean exports, no watermark")
        ]
    }


    private struct Plan: Identifiable {
        let id: String
        let product: Product
        let title: String
        let badge: String?
        let detail: String
        let period: String
        let trial: Bool
    }

    private var plans: [Plan] {
        var result: [Plan] = []
        if let yearly = subscription.yearly {
            let perWeek = subscription.perWeekPrice(of: yearly, weeks: 52)
            var badge = "BEST VALUE"
            if let saving = subscription.yearlySavingsPercent { badge = "SAVE \(saving)%" }
            result.append(Plan(id: yearly.id, product: yearly, title: "Yearly", badge: badge,
                               detail: "Just \(perWeek) per week", period: "year", trial: false))
        }
        if let monthly = subscription.monthly {
            result.append(Plan(id: monthly.id, product: monthly, title: "Monthly", badge: nil,
                               detail: "Flexible, cancel anytime", period: "month", trial: false))
        }
        if let weekly = subscription.weekly {
            let trial = weekly.id == ProductID.weeklyTrial && subscription.trialEligible
            result.append(Plan(id: weekly.id, product: weekly, title: "Weekly",
                               badge: trial ? "3 DAYS FREE" : nil,
                               detail: trial ? "Try free, then \(weekly.displayPrice) per week" : "Billed every week",
                               period: "week", trial: trial))
        }
        return result
    }

    private var selectedPlan: Plan? {
        plans.first { $0.id == selectedID } ?? plans.first
    }

    private var ctaTitle: String {
        guard let plan = selectedPlan else { return "Continue" }
        return plan.trial ? "Start free trial" : "Continue"
    }

    private var disclosure: String {
        guard let plan = selectedPlan else { return "" }
        if plan.trial {
            return "3-day free trial, then \(plan.product.displayPrice) per week. Cancel anytime in Settings."
        }
        return "\(plan.product.displayPrice) per \(plan.period). Renews automatically until cancelled."
    }


    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                topBar

                GeometryReader { geo in
                    ScrollView(showsIndicators: false) {
                        content(geo.size.height >= Self.regularLayoutMinHeight ? .regular : .compact)
                            .frame(minHeight: geo.size.height, alignment: .top)
                    }
                    .modifier(BounceOnlyWhenNeeded())
                }

                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if subscription.products.isEmpty { await subscription.loadProducts() }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { glow = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { breathe = true }
            withAnimation(.easeOut(duration: 0.7)) { appeared = true }
            if !loggedView {
                loggedView = true
                AppAnalytics.log(AppAnalytics.Event.paywallView, ["placement": placement])
            }
        }
        .onChange(of: subscription.isPro) { isPro in
            if isPro { dismiss() }
        }
        .alert("Clarity AI Pro",
               isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } }),
               actions: { Button("OK", role: .cancel) {} },
               message: { Text(alertText ?? "") })
    }


    private func content(_ density: Density) -> some View {
        VStack(spacing: 0) {
            header(density)
            Spacer(minLength: density.isCompact ? 10 : 14)
            featureList(density)
            Spacer(minLength: density.isCompact ? 10 : 14)
            planSection(density)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }


    private var topBar: some View {
        HStack {
            Button {
                restore()
            } label: {
                Text("Restore")
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
            }
            Spacer()
            IconButton(symbol: "xmark", size: 36) { closeTapped() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private func header(_ density: Density) -> some View {
        let compact = density.isCompact
        let disc: CGFloat = compact ? 44 : 60
        let glowSize: CGFloat = compact ? 76 : 100
        return VStack(spacing: compact ? 3 : 5) {
            ZStack {
                Circle()
                    .fill(Theme.goldGradient)
                    .opacity(0.35)
                    .frame(width: glowSize, height: glowSize)
                    .blur(radius: compact ? 18 : 22)
                    .scaleEffect(glow ? 1.25 : 0.9)

                Circle()
                    .fill(Theme.goldGradient)
                    .frame(width: disc, height: disc)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5))
                    .shadow(color: Theme.gold.opacity(0.6), radius: compact ? 14 : 18, x: 0, y: compact ? 5 : 7)

                Image(systemName: "crown.fill")
                    .font(.system(size: compact ? 19 : 26, weight: .bold))
                    .foregroundColor(Color(hex: 0x3A1E00))
                    .rotationEffect(.degrees(glow ? 4 : -4))
            }
            .frame(height: compact ? 56 : 78)

            Text("Clarity AI Pro")
                .font(.app(compact ? .title2 : .title, weight: .heavy))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("Everything unlocked. Nothing in your way.")
                .font(.app(compact ? .footnote : .subheadline))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private func featureList(_ density: Density) -> some View {
        let compact = density.isCompact
        let rows = stride(from: 0, to: features.count, by: 2).map { start in
            Array(start..<min(start + 2, features.count))
        }
        return VStack(alignment: .leading, spacing: compact ? 8 : 11) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .center, spacing: 10) {
                    ForEach(row, id: \.self) { index in
                        featureCell(features[index], index: index, compact: compact)
                    }
                    if row.count == 1 { Spacer(minLength: 0) }
                }
            }
        }
        .padding(compact ? 13 : 16)
        .glassCard(radius: compact ? 20 : 24)
    }

    private func featureCell(_ feature: (symbol: String, text: String), index: Int, compact: Bool) -> some View {
        let tile: CGFloat = compact ? 26 : 30
        return HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 8 : 9, style: .continuous)
                    .fill(Theme.brandGradient)
                    .frame(width: tile, height: tile)
                Image(systemName: feature.symbol)
                    .font(.system(size: compact ? 12 : 13, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(feature.text)
                .font(.app(compact ? .caption : .footnote, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -24)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1 * Double(index) + 0.15), value: appeared)
    }

    private func planSection(_ density: Density) -> some View {
        let compact = density.isCompact
        return VStack(spacing: compact ? 8 : 10) {
            if plans.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: compact ? 56 : 66)
                        .shimmering()
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 18 : 20, style: .continuous))
                }
                if !subscription.isLoadingProducts {
                    Button {
                        Task { await subscription.loadProducts() }
                    } label: {
                        Text("Couldn't load plans. Tap to retry")
                            .font(.app(.footnote, weight: .semibold))
                            .foregroundColor(Theme.fuchsia)
                    }
                }
            } else {
                ForEach(plans) { plan in
                    planRow(plan, compact: compact)
                }
            }
        }
    }

    private func planRow(_ plan: Plan, compact: Bool) -> some View {
        let selected = plan.id == selectedPlan?.id
        let radius: CGFloat = compact ? 18 : 20
        return Button {
            Haptics.select()
            AppAnalytics.log(AppAnalytics.Event.paywallPlanSelect, ["product_id": plan.id, "placement": placement])
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedID = plan.id }
        } label: {
            HStack(spacing: compact ? 12 : 14) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? Theme.fuchsia : Theme.textTertiary, lineWidth: 2)
                        .frame(width: compact ? 22 : 24, height: compact ? 22 : 24)
                    if selected {
                        Circle()
                            .fill(Theme.brandGradient)
                            .frame(width: compact ? 12 : 14, height: compact ? 12 : 14)
                            .transition(.scale)
                    }
                }

                VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.app(compact ? .subheadline : .headline, weight: .bold))
                            .foregroundColor(.white)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: 0x2A1600))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.goldGradient))
                        }
                    }
                    Text(plan.detail)
                        .font(.app(compact ? .caption : .footnote))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(plan.product.displayPrice)
                        .font(.app(compact ? .subheadline : .headline, weight: .bold))
                        .foregroundColor(.white)
                    Text("per \(plan.period)")
                        .font(.app(.caption))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, compact ? 14 : 16)
            .padding(.vertical, compact ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white.opacity(selected ? 0.13 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(selected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.stroke),
                                  lineWidth: selected ? 2 : 1)
            )
            .scaleEffect(selected ? 1 : 0.985)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Button {
                purchase()
            } label: {
                ZStack {
                    if subscription.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text(ctaTitle)
                    }
                }
                .frame(height: 22)
            }
            .buttonStyle(PrimaryButtonStyle(gradient: Theme.brandGradient, glow: Theme.fuchsia))
            .disabled(selectedPlan == nil || subscription.isPurchasing)
            .scaleEffect(breathe ? 1.015 : 1)

            Text(disclosure)
                .font(.app(.caption))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(minHeight: 30)

            HStack(spacing: 18) {
                legalLink("Terms", AppLinks.termsOfUse)
                legalLink("Privacy", AppLinks.privacyPolicy)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            LinearGradient(colors: [Theme.bg1.opacity(0), Theme.bg1.opacity(0.96)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func legalLink(_ title: String, _ urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) { openURL(url) }
        } label: {
            Text(title)
                .font(.app(.caption, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
        }
    }


    private func closeTapped() {
        AppAnalytics.log(AppAnalytics.Event.paywallClose, ["placement": placement])
        dismiss()
    }

    private func purchase() {
        guard let plan = selectedPlan else { return }
        Haptics.medium()
        let info: [String: Any] = [
            "product_id": plan.id,
            "trial": plan.trial ? 1 : 0,
            "placement": placement
        ]
        AppAnalytics.log(AppAnalytics.Event.purchaseStart, info)
        Task {
            let outcome = await subscription.purchase(plan.product)
            switch outcome {
            case .success:
                AppAnalytics.log(AppAnalytics.Event.purchaseSuccess, info)
                Haptics.success()
                dismiss()
            case .cancelled:
                AppAnalytics.log(AppAnalytics.Event.purchaseCancel, info)
            case .pending:
                AppAnalytics.log(AppAnalytics.Event.purchasePending, info)
                alertText = "Your purchase is waiting for approval. You'll get Pro as soon as it's confirmed."
            case .failed(let text):
                AppAnalytics.log(AppAnalytics.Event.purchaseFail, info)
                alertText = text
            }
        }
    }

    private func restore() {
        AppAnalytics.log(AppAnalytics.Event.restoreTap, ["placement": placement])
        Task {
            let restored = await subscription.restore()
            AppAnalytics.log(AppAnalytics.Event.restoreResult, ["restored": restored ? 1 : 0, "placement": placement])
            if restored {
                Haptics.success()
                dismiss()
            } else {
                alertText = "We couldn't find an active subscription for this Apple ID."
            }
        }
    }
}


/// Keeps the page still when everything fits, and lets it scroll (with bounce) when it doesn't.
private struct BounceOnlyWhenNeeded: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.scrollBounceBehavior(.basedOnSize)
        } else {
            content
        }
    }
}


struct PaywallCover: ViewModifier {
    @Binding var isPresented: Bool
    var placement: String
    @EnvironmentObject private var subscription: SubscriptionManager

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            PaywallView(placement: placement)
                .environmentObject(subscription)
        }
    }
}

extension View {
    func proPaywall(isPresented: Binding<Bool>, placement: String = "other") -> some View {
        modifier(PaywallCover(isPresented: isPresented, placement: placement))
    }
}
