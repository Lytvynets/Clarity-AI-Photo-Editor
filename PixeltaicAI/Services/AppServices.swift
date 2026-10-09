
import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif


/// Starts Firebase only when `GoogleService-Info.plist` is really bundled, so a missing file
/// switches analytics / Remote Config off instead of crashing the app on launch.
enum FirebaseBootstrap {

    private(set) static var isConfigured = false

    static func configureIfPossible() {
        #if canImport(FirebaseCore)
        guard !isConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("⚠️ GoogleService-Info.plist not found. Firebase Analytics and Remote Config are off.")
            return
        }
        FirebaseApp.configure()
        isConfigured = true
        AppAnalytics.setUserProperty(AppAnalytics.plan, name: "plan")
        #endif
    }
}


/// Thin wrapper around Firebase Analytics. Safe to call from anywhere: it does nothing when
/// Firebase is not linked or not configured, and prints every event in debug builds.
enum AppAnalytics {

    /// "free", "trial" or "pro". Kept up to date by `SubscriptionManager`.
    static var plan = "free" {
        didSet {
            if plan != oldValue { setUserProperty(plan, name: "plan") }
        }
    }

    enum Event {
        static let onboardingComplete = "onboarding_complete"

        static let paywallView = "paywall_view"
        static let paywallClose = "paywall_close"
        static let paywallPlanSelect = "paywall_plan_select"
        static let purchaseStart = "purchase_start"
        static let purchaseSuccess = "purchase_success"
        static let purchaseCancel = "purchase_cancel"
        static let purchasePending = "purchase_pending"
        static let purchaseFail = "purchase_fail"
        static let restoreTap = "restore_tap"
        static let restoreResult = "restore_result"

        static let toolOpen = "tool_open"
        static let photoPicked = "photo_picked"
        static let runStart = "run_start"
        static let runSuccess = "run_success"
        static let runFail = "run_fail"
        static let runCancel = "run_cancel"
        static let resultSave = "result_save"
        static let resultShare = "result_share"

        static let runGateView = "run_gate_view"
        static let upgradeTap = "upgrade_tap"
        static let rewardedStart = "rewarded_start"
        static let rewardedEarned = "rewarded_earned"
        static let rewardedSkipped = "rewarded_skipped"
        static let rewardedUnavailable = "rewarded_unavailable"
        static let proLimitReached = "pro_limit_reached"
    }

    static func log(_ event: String, _ parameters: [String: Any] = [:]) {
        var params = parameters
        if params["plan"] == nil { params["plan"] = plan }

        #if DEBUG
        print("📊 \(event) \(params)")
        #endif

        #if canImport(FirebaseAnalytics)
        guard FirebaseBootstrap.isConfigured else { return }
        Analytics.logEvent(event, parameters: params)
        #endif
    }

    static func setUserProperty(_ value: String?, name: String) {
        #if canImport(FirebaseAnalytics)
        guard FirebaseBootstrap.isConfigured else { return }
        Analytics.setUserProperty(value, forName: name)
        #endif
    }
}


extension ClaidError {

    /// Short, stable code for analytics (`no_credits` is the one to set an alert on).
    var analyticsCode: String {
        switch self {
        case .offline: return "offline"
        case .timeout: return "timeout"
        case .unauthorized: return "unauthorized"
        case .noCredits: return "no_credits"
        case .rateLimited: return "rate_limited"
        case .invalidRequest: return "invalid_request"
        case .contentFiltered: return "content_filtered"
        case .server(let code): return "server_\(code)"
        case .badResponse: return "bad_response"
        case .aiEditFailed: return "ai_edit_failed"
        }
    }
}
