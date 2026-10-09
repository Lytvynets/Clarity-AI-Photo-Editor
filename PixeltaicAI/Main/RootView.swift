

import SwiftUI

struct RootView: View {

    @AppStorage("onboarding.v2.done") private var onboardingDone = false

    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var ads: AdManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var showSplash = true
    @State private var showLaunchPaywall = false

    var body: some View {
        ZStack {
            AppBackground()

            if onboardingDone {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    AppAnalytics.log(AppAnalytics.Event.onboardingComplete)
                    withAnimation(.easeInOut(duration: 0.5)) { onboardingDone = true }
                }
                .transition(.opacity)
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .proPaywall(isPresented: $showLaunchPaywall, placement: "launch")
        .task {
     
            try? await Task.sleep(nanoseconds: 2_100_000_000)
            withAnimation(.easeOut(duration: 0.45)) { showSplash = false }

            guard onboardingDone, !subscription.isPro else { return }
            try? await Task.sleep(nanoseconds: 700_000_000)
            // In the EU the consent form may be on screen right now; wait so the two don't collide.
            await ads.waitForConsentFlow(timeout: 20)
            guard !subscription.isPro else { return }
            showLaunchPaywall = true
        }
        .task(id: onboardingDone) {
            guard onboardingDone else { return }
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if !subscription.isPro { ads.start() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                usage.rollIfNeeded()
                Task { await subscription.refreshEntitlements() }
                Task { await RemoteSettings.shared.refresh() }
            }
        }
    }
}

struct SplashView: View {

    @State private var appear = false
    @State private var glow = false
    @State private var ringRotation = 0.0

    var body: some View {
        ZStack {
            Theme.bg0.ignoresSafeArea()

            Circle()
                .fill(Theme.violet.opacity(0.35))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .scaleEffect(glow ? 1.15 : 0.85)
                .opacity(glow ? 0.9 : 0.55)

            Circle()
                .fill(Theme.fuchsia.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: glow ? 44 : -26, y: glow ? -30 : 26)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            AngularGradient(colors: [Theme.violet, Theme.fuchsia, Theme.cyan, Theme.violet],
                                            center: .center),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(ringRotation))
                        .opacity(appear ? 0.9 : 0)

                    Image("Logo v2-2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 112, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 56, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: Theme.violet.opacity(0.7), radius: 30, x: 0, y: 10)
                        .rotationEffect(.degrees(appear ? 0 : -8))
                        .scaleEffect(appear ? 1 : 0.7)
                        .opacity(appear ? 1 : 0)
                }

                Text("Clarity AI")
                    .font(.app(.title, weight: .heavy))
                    .foregroundColor(.white)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appear = true }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { glow = true }
            withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { ringRotation = 360 }
        }
    }
}
