

import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscription: SubscriptionManager

    @State private var selectedID: String = ProductID.yearly
    @State private var glow = false
    @State private var breathe = false
    @State private var appeared = false
    @State private var alertText: String?

    private let features: [(symbol: String, text: String)] = [
        ("nosign", "No ads, ever"),
        ("infinity", "Unlimited edits and creations"),
        ("arrow.up.left.and.arrow.down.right", "4× AI upscale"),
        ("square.grid.2x2.fill", "Up to 4 images per prompt"),
        ("checkmark.seal.fill", "Clean exports without watermark")
    ]


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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        header
                        featureList
                        planSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
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
        }
        .onChange(of: subscription.isPro) { isPro in
            if isPro { dismiss() }
        }
        .alert("Clarity Ai Pro",
               isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } }),
               actions: { Button("OK", role: .cancel) {} },
               message: { Text(alertText ?? "") })
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
            IconButton(symbol: "xmark", size: 36) { dismiss() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.goldGradient)
                    .opacity(0.35)
                    .frame(width: 130, height: 130)
                    .blur(radius: 26)
                    .scaleEffect(glow ? 1.25 : 0.9)

                Circle()
                    .fill(Theme.goldGradient)
                    .frame(width: 84, height: 84)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5))
                    .shadow(color: Theme.gold.opacity(0.6), radius: 20, x: 0, y: 8)

                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(hex: 0x3A1E00))
                    .rotationEffect(.degrees(glow ? 4 : -4))
            }
            .frame(height: 120)

            Text("Clarity Ai Pro")
                .font(.app(.largeTitle, weight: .heavy))
                .foregroundColor(.white)

            Text("Everything unlocked. Nothing in your way.")
                .font(.app(.subheadline))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.brandGradient)
                            .frame(width: 34, height: 34)
                        Image(systemName: feature.symbol)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text(feature.text)
                        .font(.app(.body, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -24)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.12 * Double(index) + 0.15), value: appeared)
            }
        }
        .padding(18)
        .glassCard(radius: 24)
    }

    private var planSection: some View {
        VStack(spacing: 12) {
            if plans.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 74)
                        .shimmering()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                    planRow(plan)
                }
            }
        }
    }

    private func planRow(_ plan: Plan) -> some View {
        let selected = plan.id == selectedPlan?.id
        return Button {
            Haptics.select()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedID = plan.id }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? Theme.fuchsia : Theme.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if selected {
                        Circle()
                            .fill(Theme.brandGradient)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.app(.headline, weight: .bold))
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
                        .font(.app(.footnote))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.product.displayPrice)
                        .font(.app(.headline, weight: .bold))
                        .foregroundColor(.white)
                    Text("per \(plan.period)")
                        .font(.app(.caption))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(selected ? 0.13 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Theme.stroke),
                                  lineWidth: selected ? 2 : 1)
            )
            .scaleEffect(selected ? 1 : 0.985)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
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
        .padding(.top, 12)
        .padding(.bottom, 8)
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


    private func purchase() {
        guard let plan = selectedPlan else { return }
        Haptics.medium()
        Task {
            let outcome = await subscription.purchase(plan.product)
            switch outcome {
            case .success:
                Haptics.success()
                dismiss()
            case .cancelled:
                break
            case .pending:
                alertText = "Your purchase is waiting for approval. You'll get Pro as soon as it's confirmed."
            case .failed(let text):
                alertText = text
            }
        }
    }

    private func restore() {
        Task {
            let restored = await subscription.restore()
            if restored {
                Haptics.success()
                dismiss()
            } else {
                alertText = "We couldn't find an active subscription for this Apple ID."
            }
        }
    }
}


struct PaywallCover: ViewModifier {
    @Binding var isPresented: Bool
    @EnvironmentObject private var subscription: SubscriptionManager

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $isPresented) {
            PaywallView()
                .environmentObject(subscription)
        }
    }
}

extension View {
    func proPaywall(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallCover(isPresented: isPresented))
    }
}
