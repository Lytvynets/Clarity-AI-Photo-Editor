
import SwiftUI

private struct OnboardingPage {
    let title: String
    let subtitle: String
}

struct OnboardingView: View {

    var onFinish: () -> Void

    @EnvironmentObject private var subscription: SubscriptionManager

    @State private var page = 0
    @State private var showPaywall = false
    @State private var finishing = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(title: "Bring photos back to life",
                       subtitle: "AI restores lost detail, removes noise and upscales up to 4× in one tap."),
        OnboardingPage(title: "Cutouts and blur, instantly",
                       subtitle: "Remove or blur any background with clean edges. Pick a color or keep it transparent."),
        OnboardingPage(title: "Edit with your words",
                       subtitle: "Type what you want to change, like “make it snowy”, and watch it happen."),
        OnboardingPage(title: "Create anything you imagine",
                       subtitle: "Turn a sentence into stunning images. Save, share, and keep editing them.")
    ]

    private var lastIndex: Int { pages.count - 1 }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < lastIndex {
                        Button {
                            Haptics.tap()
                            withAnimation(.easeInOut) { page = lastIndex }
                        } label: {
                            Text("Skip")
                                .font(.app(.subheadline, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 12)

                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                dots
                    .padding(.top, 6)
                    .padding(.bottom, 20)

                Button {
                    next()
                } label: {
                    Text(page == lastIndex ? "Get started" : "Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: page)
        .proPaywall(isPresented: $showPaywall)
        .onChange(of: showPaywall) { presented in
            if !presented && finishing { onFinish() }
        }
    }

    private func pageView(_ index: Int) -> some View {
        VStack(spacing: 26) {
            Spacer(minLength: 0)

            illustration(index)
                .frame(maxWidth: 340)
                .frame(height: 330)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                Text(pages[index].title)
                    .font(.app(.title, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(pages[index].subtitle)
                    .font(.app(.body))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func illustration(_ index: Int) -> some View {
        switch index {
        case 0: RestoreIllustration()
        case 1: BackgroundIllustration()
        case 2: MagicIllustration()
        default: CreateIllustration()
        }
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.2)))
                    .frame(width: index == page ? 26 : 8, height: 8)
            }
        }
    }

    private func next() {
        Haptics.tap()
        if page < lastIndex {
            withAnimation(.easeInOut) { page += 1 }
        } else if subscription.isPro {
            onFinish()
        } else {
            finishing = true
            showPaywall = true
        }
    }
}


private struct RestoreIllustration: View {

    private let pair: (UIImage, UIImage)? = DemoAssets.beforeAfter()

    var body: some View {
        Group {
            if let pair {
                BeforeAfterSlider(before: pair.0, after: pair.1)
                    .shadow(color: Theme.violet.opacity(0.45), radius: 26, x: 0, y: 14)
            } else {
                GradientTile(symbol: "wand.and.stars", colors: [Theme.violet, Theme.blue], size: 140)
            }
        }
    }
}

private struct BackgroundIllustration: View {
    @State private var dash: CGFloat = 0
    @State private var bob = false

    var body: some View {
        ZStack {
            CheckerboardView()
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2.5, dash: [10, 7], dashPhase: dash))
                .foregroundColor(Theme.fuchsia)
                .frame(width: 180, height: 220)

            Image(systemName: "person.fill")
                .font(.system(size: 130, weight: .bold))
                .foregroundStyle(LinearGradient(colors: [Theme.pink, Theme.orange], startPoint: .top, endPoint: .bottom))
                .shadow(color: Theme.pink.opacity(0.5), radius: 20)
                .offset(y: bob ? -6 : 6)

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "scissors")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Theme.brandGradient))
                        .shadow(color: Theme.fuchsia.opacity(0.6), radius: 12)
                        .rotationEffect(.degrees(bob ? 12 : -12))
                }
                Spacer()
            }
            .padding(20)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) { dash = 34 }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

private struct MagicIllustration: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(Theme.fuchsia)
                TypewriterText(phrases: ["Make it snowy", "Add sunglasses", "Golden hour light", "Turn into watercolor"])
                    .font(.app(.headline, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .glassCard(radius: 22)

            Image(systemName: "arrow.down")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .offset(y: pulse ? 5 : -5)

            HStack(spacing: 14) {
                mini(colors: [Theme.blue, Theme.cyan], symbol: "sun.max.fill")
                mini(colors: [Theme.violet, Theme.fuchsia], symbol: "snowflake")
                mini(colors: [Theme.orange, Theme.gold], symbol: "camera.filters")
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func mini(colors: [Color], symbol: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(height: 96)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
        .scaleEffect(pulse ? 1.03 : 0.97)
    }
}

private struct CreateIllustration: View {
    @State private var glow = false

    private let tiles: [[Color]] = [
        [Theme.fuchsia, Theme.violet],
        [Theme.cyan, Theme.blue],
        [Theme.orange, Theme.pink],
        [Theme.mint, Theme.cyan]
    ]
    private let symbols = ["moon.stars.fill", "mountain.2.fill", "flame.fill", "leaf.fill"]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(0..<4, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(LinearGradient(colors: tiles[index], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: symbols[index])
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 42, y: -42)
                        .opacity(glow ? 1 : 0.3)
                        .scaleEffect(glow ? 1.2 : 0.8)
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: tiles[index][0].opacity(0.45), radius: 14, x: 0, y: 8)
                .scaleEffect(glow ? 1 : 0.96)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(index) * 0.25), value: glow)
            }
        }
        .onAppear { glow = true }
    }
}


enum DemoAssets {

    static func beforeAfter() -> (UIImage, UIImage)? {
        guard let image = UIImage(named: "OnbIMG1"), let cg = image.cgImage else { return nil }
        guard cg.width == 393, cg.height >= 518 else { return nil }
        let width = cg.width
        let topRect = CGRect(x: 0, y: 0, width: width, height: 256)
        let bottomRect = CGRect(x: 0, y: 262, width: width, height: 256)
        guard let top = cg.cropping(to: topRect), let bottom = cg.cropping(to: bottomRect) else { return nil }
        return (UIImage(cgImage: top), UIImage(cgImage: bottom))
    }
}
