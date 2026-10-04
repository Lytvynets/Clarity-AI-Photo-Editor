

import SwiftUI

struct StudioView: View {

    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var router: Router

    @State private var showPaywall = false
    @State private var appeared = false
    @State private var floating = false

    private let gridColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    private let gridTools: [Tool] = [.enhance, .background, .blur, .color]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                header
                    .reveal(appeared, delay: 0.0)

                heroRow
                    .reveal(appeared, delay: 0.08)

                toolsSection
                    .reveal(appeared, delay: 0.16)

                if !library.items.isEmpty {
                    recentSection
                        .reveal(appeared, delay: 0.24)
                }

                if !subscription.isPro {
                    upsell
                        .reveal(appeared, delay: 0.3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .proPaywall(isPresented: $showPaywall)
        .onAppear {
            withAnimation(.easeOut(duration: 0.1)) { appeared = true }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { floating = true }
        }
    }


    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Clarity AI")
                    .font(.app(.largeTitle, weight: .heavy))
                    .foregroundColor(.white)
                if subscription.isPro {
                    Text("Pro · everything unlocked")
                        .font(.app(.subheadline, weight: .medium))
                        .foregroundColor(Theme.gold)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").font(.system(size: 11, weight: .bold))
                        Text("\(usage.remaining) free runs left today")
                            .font(.app(.subheadline, weight: .medium))
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            if subscription.isPro {
                ProBadge()
            } else {
                Button {
                    Haptics.tap()
                    showPaywall = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill").font(.system(size: 12, weight: .bold))
                        Text("Go Pro").font(.app(.subheadline, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x2A1600))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Theme.goldGradient))
                    .shadow(color: Theme.gold.opacity(0.4), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(PressableStyle(scale: 0.94))
            }
        }
    }


    private var heroRow: some View {
        HStack(spacing: 14) {
            heroCard(title: "Create with AI",
                     subtitle: "Turn words into images",
                     symbol: "wand.and.rays",
                     colors: [Theme.fuchsia, Theme.violet]) {
                router.openCreate()
            }
            heroCard(title: "Magic Edit",
                     subtitle: "Change photos with a prompt",
                     symbol: "sparkles",
                     colors: [Theme.blue, Theme.violet]) {
                router.openEditor(tool: .magic)
            }
        }
    }

    private func heroCard(title: String,
                          subtitle: String,
                          symbol: String,
                          colors: [Color],
                          action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "sparkle")
                    .font(.system(size: 90, weight: .bold))
                    .foregroundColor(.white.opacity(0.10))
                    .offset(x: 18, y: floating ? 10 : 22)

                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: symbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer(minLength: 24)
                    Text(title)
                        .font(.app(.headline, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.app(.caption))
                        .foregroundColor(.white.opacity(0.82))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 156)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: (colors.first ?? Theme.violet).opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PressableStyle())
    }


    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Photo tools")

            LazyVGrid(columns: gridColumns, spacing: 14) {
                ForEach(gridTools) { tool in
                    toolCard(tool)
                }
            }

            wideToolCard(.resize)
        }
    }

    private func toolCard(_ tool: Tool) -> some View {
        Button {
            Haptics.tap()
            router.openEditor(tool: tool)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                GradientTile(symbol: tool.symbol, colors: tool.colors, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.title)
                        .font(.app(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(tool.subtitle)
                        .font(.app(.caption))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .glassCard(radius: 22)
        }
        .buttonStyle(PressableStyle())
    }

    private func wideToolCard(_ tool: Tool) -> some View {
        Button {
            Haptics.tap()
            router.openEditor(tool: tool)
        } label: {
            HStack(spacing: 14) {
                GradientTile(symbol: tool.symbol, colors: tool.colors, size: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.title)
                        .font(.app(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                    Text(tool.subtitle)
                        .font(.app(.caption))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glassCard(radius: 22)
        }
        .buttonStyle(PressableStyle())
    }


    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Recent", trailing: "See all", trailingAction: {
                router.tab = .library
            })

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(library.items.prefix(8)) { item in
                        Button {
                            Haptics.tap()
                            router.tab = .library
                        } label: {
                            LibraryThumbnail(item: item)
                                .frame(width: 104, height: 104)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .strokeBorder(Theme.stroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }


    private var upsell: some View {
        Button {
            Haptics.tap()
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.goldGradient).frame(width: 52, height: 52)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: 0x3A1E00))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Go Pro")
                        .font(.app(.headline, weight: .bold))
                        .foregroundColor(.white)
                    Text("No ads · Unlimited runs · 4× upscale")
                        .font(.app(.caption))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.gold)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.gold.opacity(0.22), Theme.orange.opacity(0.10)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

private extension View {
    func reveal(_ visible: Bool, delay: Double) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 18)
            .animation(.spring(response: 0.7, dampingFraction: 0.82).delay(delay), value: visible)
    }
}
