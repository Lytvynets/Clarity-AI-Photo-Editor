

import SwiftUI

struct SettingsView: View {

    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var ads: AdManager

    @State private var showPaywall = false
    @State private var showShare = false
    @State private var showClearDialog = false
    @State private var isRestoring = false
    @State private var alertText: String?

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.app(.largeTitle, weight: .heavy))
                    .foregroundColor(.white)

                planCard

                if !subscription.isPro {
                    usageCard
                }

                section("Support") {
                    row(icon: "star.fill", tint: Theme.gold, title: "Rate Clarity AI") {
                        open(AppLinks.writeReview)
                    }
                    divider
                    row(icon: "square.and.arrow.up", tint: Theme.blue, title: "Share the app") {
                        showShare = true
                    }
                    divider
                    row(icon: "square.grid.2x2.fill", tint: Theme.mint, title: "More apps") {
                        open(AppLinks.otherApps)
                    }
                }

                section("Purchases") {
                    row(icon: "arrow.clockwise", tint: Theme.violet, title: "Restore purchases", busy: isRestoring) {
                        restore()
                    }
                    if subscription.isPro {
                        divider
                        row(icon: "creditcard.fill", tint: Theme.fuchsia, title: "Manage subscription") {
                            open(AppLinks.manageSubscriptions)
                        }
                    }
                }

                section("Privacy") {
                    row(icon: "hand.raised.fill", tint: Theme.cyan, title: "Privacy Policy") {
                        open(AppLinks.privacyPolicy)
                    }
                    divider
                    row(icon: "doc.text.fill", tint: Theme.blue, title: "Terms of Use") {
                        open(AppLinks.termsOfUse)
                    }
                    if ads.isPrivacyOptionsRequired {
                        divider
                        row(icon: "person.badge.shield.checkmark.fill", tint: Theme.mint, title: "Ad privacy choices") {
                            Task { await ads.presentPrivacyOptions() }
                        }
                    }
                }

                section("Storage") {
                    row(icon: "trash.fill",
                        tint: Theme.danger,
                        title: "Delete all saved results",
                        subtitle: library.items.isEmpty ? "Nothing saved" : "\(library.items.count) items on this device") {
                        if !library.items.isEmpty { showClearDialog = true }
                    }
                }

                VStack(spacing: 4) {
                    Text("Clarity AI")
                        .font(.app(.footnote, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                    Text(versionText)
                        .font(.app(.caption))
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .proPaywall(isPresented: $showPaywall)
        .sheet(isPresented: $showShare) {
            if let url = URL(string: AppLinks.appStore) {
                ShareSheet(items: [url])
            }
        }
        .confirmationDialog("Delete all saved results?", isPresented: $showClearDialog, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) { library.deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .alert("Purchases",
               isPresented: Binding(get: { alertText != nil }, set: { if !$0 { alertText = nil } }),
               actions: { Button("OK", role: .cancel) {} },
               message: { Text(alertText ?? "") })
    }


    private var planCard: some View {
        Button {
            if !subscription.isPro { showPaywall = true }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(subscription.isPro ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Color.white.opacity(0.10)))
                        .frame(width: 52, height: 52)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(subscription.isPro ? Color(hex: 0x3A1E00) : Theme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(subscription.isPro ? "Clarity Ai Pro" : "Free plan")
                        .font(.app(.headline, weight: .bold))
                        .foregroundColor(.white)
                    Text(subscription.isPro ? "No ads, unlimited runs, 4× upscale" : "Upgrade for no ads and unlimited runs")
                        .font(.app(.caption))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if subscription.isPro {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.mint)
                } else {
                    Text("Upgrade")
                        .font(.app(.footnote, weight: .bold))
                        .foregroundColor(Color(hex: 0x2A1600))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.goldGradient))
                }
            }
            .padding(16)
            .glassCard(radius: 24)
        }
        .buttonStyle(PressableStyle(scale: 0.98))
    }

    private var usageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Today's free runs", systemImage: "bolt.fill")
                    .font(.app(.subheadline, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(usage.remaining) / \(usage.dailyLimit)")
                    .font(.app(.subheadline, weight: .bold))
                    .foregroundColor(Theme.fuchsia)
                    .monospacedDigit()
            }
            HStack(spacing: 6) {
                ForEach(0..<usage.dailyLimit, id: \.self) { index in
                    Capsule()
                        .fill(index < usage.remaining ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.12)))
                        .frame(height: 8)
                }
            }
            Text("\(usage.resetText). Watch a short video to unlock each run.")
                .font(.app(.caption))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .glassCard(radius: 22)
    }


    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(Theme.textTertiary)
                .padding(.leading, 6)
            VStack(spacing: 0) {
                content()
            }
            .glassCard(radius: 20)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(height: 1)
            .padding(.leading, 60)
    }

    private func row(icon: String,
                     tint: Color,
                     title: String,
                     subtitle: String? = nil,
                     busy: Bool = false,
                     action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tint.opacity(0.9))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.app(.body, weight: .medium))
                        .foregroundColor(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.app(.caption))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                Spacer()
                if busy {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.99))
    }


    private func open(_ string: String) {
        if let url = URL(string: string) { openURL(url) }
    }

    private func restore() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let restored = await subscription.restore()
            isRestoring = false
            if restored {
                Haptics.success()
                alertText = "Welcome back! Clarity Ai Pro is active."
            } else {
                alertText = "We couldn't find an active subscription for this Apple ID."
            }
        }
    }
}
