

import Foundation
import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

enum RewardOutcome {
    case earned
    case skipped
    case unavailable
}

#if canImport(GoogleMobileAds)

@MainActor
final class AdManager: NSObject, ObservableObject {

    @Published private(set) var adsAllowed = false
    @Published private(set) var isRewardedReady = false
    @Published private(set) var isPrivacyOptionsRequired = false

    private var startTask: Task<Void, Never>?
    private var rewardedAd: RewardedAd?
    private var isLoadingRewarded = false
    private var continuation: CheckedContinuation<RewardOutcome, Never>?
    private var earned = false


    func start() {
        guard startTask == nil else { return }
        startTask = Task { await self.performStart() }
    }

    func ensureStarted() async {
        start()
        await startTask?.value
    }

    private func performStart() async {
        #if canImport(UserMessagingPlatform)
        await gatherConsent()
        #endif

        #if canImport(UserMessagingPlatform)
        guard ConsentInformation.shared.canRequestAds else {
            adsAllowed = false
            return
        }
        #endif

        await MobileAds.shared.start()
        adsAllowed = true
        await loadRewarded()
    }

    #if canImport(UserMessagingPlatform)
    private func gatherConsent() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let parameters = RequestParameters()
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                Task { @MainActor in
                    if let error {
                        print("⚠️ Consent info update failed: \(error.localizedDescription)")
                    } else {
                        do {
                            try await ConsentForm.loadAndPresentIfRequired(from: nil)
                        } catch {
                            print("⚠️ Consent form failed: \(error.localizedDescription)")
                        }
                    }
                    self.isPrivacyOptionsRequired =
                        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
                    continuation.resume()
                }
            }
        }
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            print("⚠️ Privacy options failed: \(error.localizedDescription)")
        }
    }
    #else
    func presentPrivacyOptions() async {}
    #endif


    func loadRewarded() async {
        guard adsAllowed, !isLoadingRewarded, rewardedAd == nil else { return }
        isLoadingRewarded = true
        defer { isLoadingRewarded = false }
        do {
            let ad = try await RewardedAd.load(with: AdConfig.rewardedID, request: Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            isRewardedReady = true
        } catch {
            isRewardedReady = false
            print("⚠️ Rewarded ad failed to load: \(error.localizedDescription)")
        }
    }

    private func loadRewardedWithTimeout(seconds: Double) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRewarded() }
            group.addTask { try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000)) }
            _ = await group.next()
            group.cancelAll()
        }
    }

    func showRewarded() async -> RewardOutcome {
        await ensureStarted()
        guard adsAllowed else { return .unavailable }
        if rewardedAd == nil {
            await loadRewardedWithTimeout(seconds: 8)
        }
        guard let ad = rewardedAd else { return .unavailable }
        guard continuation == nil else { return .unavailable }

        rewardedAd = nil
        isRewardedReady = false
        earned = false

        return await withCheckedContinuation { (continuation: CheckedContinuation<RewardOutcome, Never>) in
            self.continuation = continuation
            ad.present(from: nil) {
                Task { @MainActor in
                    self.earned = true
                }
            }
        }
    }

    private func finishPresentation(_ outcome: RewardOutcome) {
        if let continuation {
            self.continuation = nil
            continuation.resume(returning: outcome)
        }
        Task { await self.loadRewarded() }
    }
}

extension AdManager: FullScreenContentDelegate {

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.finishPresentation(self.earned ? .earned : .skipped)
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.finishPresentation(.unavailable)
        }
    }
}

#else

// Fallback used until the Google Mobile Ads package is added to the project.
@MainActor
final class AdManager: NSObject, ObservableObject {
    @Published private(set) var adsAllowed = false
    @Published private(set) var isRewardedReady = false
    @Published private(set) var isPrivacyOptionsRequired = false

    func start() {}
    func ensureStarted() async {}
    func loadRewarded() async {}
    func showRewarded() async -> RewardOutcome { .unavailable }
    func presentPrivacyOptions() async {}
}

#endif
