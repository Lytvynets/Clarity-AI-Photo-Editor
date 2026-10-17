import Foundation

/// Decides when a paywall may appear on its own, so that offers don't pile up.
/// Everything is stored on the device; the limits come from Remote Config.
enum PaywallTiming {

    private static let lastShownKey = "paywall.lastShown.v1"
    private static let savesKey = "paywall.saves.v1"
    private static let saveOfferShownKey = "paywall.saveOfferShown.v1"

    /// Paywalls that follow a save wait at least this long after any other paywall.
    private static let minHoursBetweenOffers = 0.17

    /// Remember that a paywall is on screen right now (whatever opened it).
    static func markShown() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastShownKey)
    }

    private static func hoursSinceLastShown() -> Double? {
        let stored = UserDefaults.standard.double(forKey: lastShownKey)
        guard stored > 0 else { return nil }
        return max(0, Date().timeIntervalSince1970 - stored) / 3600
    }

    /// The paywall that opens on its own at launch: not again within `launch_paywall_gap_hours`
    /// of the last time any paywall was shown (0 = on every launch).
    static func launchAllowed() -> Bool {
        let gap = RemoteSettings.shared.int(.launchPaywallGapHours)
        guard gap > 0 else { return true }
        guard let hours = hoursSinceLastShown() else { return true }
        return hours >= Double(gap)
    }

    /// Call after every successful save by someone without Pro. Returns true once per device, on the
    /// Nth save (`save_paywall_at`), when the paywall should be offered: the photo is saved, so this is
    /// the moment the watermark and the Pro tools make the most sense.
    static func shouldOfferAfterSave() -> Bool {
        let at = RemoteSettings.shared.int(.savePaywallAt)
        guard at > 0 else { return false }

        let defaults = UserDefaults.standard
        let saves = defaults.integer(forKey: savesKey) + 1
        defaults.set(saves, forKey: savesKey)

        guard saves >= at, !defaults.bool(forKey: saveOfferShownKey) else { return false }
        if let hours = hoursSinceLastShown(), hours < minHoursBetweenOffers { return false }

        defaults.set(true, forKey: saveOfferShownKey)
        return true
    }
}
