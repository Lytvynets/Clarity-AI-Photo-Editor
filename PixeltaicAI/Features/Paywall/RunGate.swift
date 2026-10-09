

import SwiftUI

struct RunGateRequest: Identifiable {
    let id = UUID()
    let cost: Int
    let title: String
    /// Tool id, used for analytics only.
    var tool: String = ""
    let action: () -> Void
}

struct RunGateSheet: View {
    let request: RunGateRequest
    var onApproved: () -> Void
    var onUpgrade: () -> Void
    var onClose: () -> Void

    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var ads: AdManager

    @State private var isWorking = false
    @State private var notice: String?
    @State private var pulse = false

    private var canRun: Bool { usage.remaining >= request.cost }

    /// The daily free budget is smaller than the price of this run, so no amount of waiting helps.
    private var needsPro: Bool { request.cost > usage.dailyLimit }

    private var heading: String {
        if canRun { return "Unlock this run" }
        return needsPro ? "This one is for Pro" : "Free runs used up"
    }

    private var subtitle: String {
        if needsPro {
            return "\(request.title) needs more than the free daily allowance. Go Pro to run it."
        }
        if canRun {
            var text = "Watch a short video and \(request.title) runs for free."
            if request.cost > 1 { text += " This one uses \(request.cost) runs." }
            return text
        }
        return "\(usage.resetText). Go Pro to keep creating right now."
    }

    var body: some View {
        ZStack {
            Color(hex: 0x120A24).ignoresSafeArea()

            VStack(spacing: 18) {
                icon
                    .padding(.top, 10)

                VStack(spacing: 8) {
                    Text(heading)
                        .font(.app(.title2, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.app(.subheadline))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                pips

                VStack(spacing: 10) {
                    if canRun {
                        Button(action: watch) {
                            HStack(spacing: 8) {
                                if isWorking {
                                    ProgressView().tint(.white)
                                    Text("Loading video…")
                                } else {
                                    Image(systemName: "play.rectangle.fill")
                                    Text("Watch video · Run free")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isWorking)

                        Button {
                            upgradeTapped()
                        } label: {
                            HStack(spacing: 8) {
                                ProBadge(compact: true)
                                Text("Go Pro · no ads, more runs")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isWorking)
                    } else {
                        Button {
                            upgradeTapped()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                Text("Go Pro")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(gradient: Theme.goldGradient, glow: Theme.orange))

                        Button {
                            onClose()
                        } label: {
                            Text("Maybe later")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }

                if let notice {
                    Text(notice)
                        .font(.app(.footnote, weight: .medium))
                        .foregroundColor(Theme.gold)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true }
            AppAnalytics.log(AppAnalytics.Event.runGateView,
                             ["tool": request.tool, "cost": request.cost, "can_run": canRun ? 1 : 0])
        }
        .animation(.easeInOut(duration: 0.25), value: notice)
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(canRun ? Theme.brandGradient : Theme.goldGradient)
                .opacity(0.3)
                .frame(width: 96, height: 96)
                .scaleEffect(pulse ? 1.18 : 0.95)
            Circle()
                .fill(canRun ? Theme.brandGradient : Theme.goldGradient)
                .frame(width: 66, height: 66)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
            Image(systemName: canRun ? "play.fill" : "hourglass")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(height: 96)
    }

    private var pips: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<usage.dailyLimit, id: \.self) { index in
                    Capsule()
                        .fill(index < usage.remaining ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.12)))
                        .frame(height: 8)
                }
            }
            Text("\(usage.remaining) of \(usage.dailyLimit) free runs left today")
                .font(.app(.caption, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
        }
    }

    private func upgradeTapped() {
        AppAnalytics.log(AppAnalytics.Event.upgradeTap, ["tool": request.tool, "can_run": canRun ? 1 : 0])
        onUpgrade()
    }

    private func watch() {
        guard !isWorking else { return }
        isWorking = true
        notice = nil
        let info: [String: Any] = ["tool": request.tool, "cost": request.cost]
        AppAnalytics.log(AppAnalytics.Event.rewardedStart, info)
        Task {
            let outcome = await ads.showRewarded()
            isWorking = false
            switch outcome {
            case .earned:
                AppAnalytics.log(AppAnalytics.Event.rewardedEarned, info)
                approve()
            case .unavailable:
                AppAnalytics.log(AppAnalytics.Event.rewardedUnavailable, info)
                if FreeTier.allowRunWhenAdUnavailable {
                    approve()
                } else {
                    notice = "No video is available right now. Please try again in a moment."
                }
            case .skipped:
                AppAnalytics.log(AppAnalytics.Event.rewardedSkipped, info)
                Haptics.warning()
                notice = "Watch the whole video to unlock your free run."
            }
        }
    }

    private func approve() {
        usage.consume(request.cost)
        Haptics.success()
        onApproved()
    }
}

struct RunGateModifier: ViewModifier {
    @Binding var request: RunGateRequest?
    var onUpgrade: () -> Void

    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var ads: AdManager

    @State private var pendingAction: (() -> Void)?
    @State private var wantsUpgrade = false

    func body(content: Content) -> some View {
        content.sheet(item: $request, onDismiss: handleDismiss) { current in
            RunGateSheet(request: current,
                         onApproved: {
                             pendingAction = current.action
                             request = nil
                         },
                         onUpgrade: {
                             wantsUpgrade = true
                             request = nil
                         },
                         onClose: {
                             request = nil
                         })
                .environmentObject(usage)
                .environmentObject(ads)
                .presentationDetents([.height(470)])
                .presentationDragIndicator(.visible)
        }
    }

    private func handleDismiss() {
        if let action = pendingAction {
            pendingAction = nil
            action()
        } else if wantsUpgrade {
            wantsUpgrade = false
            onUpgrade()
        }
    }
}

extension View {
    func runGate(_ request: Binding<RunGateRequest?>, onUpgrade: @escaping () -> Void) -> some View {
        modifier(RunGateModifier(request: request, onUpgrade: onUpgrade))
    }
}
