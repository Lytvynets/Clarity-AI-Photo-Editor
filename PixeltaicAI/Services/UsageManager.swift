
import Foundation

/// Run-unit accounting for the free plan, free trials and the Pro fair-use cap.
///
/// The counters are mirrored into the Keychain (and UserDefaults), so deleting and reinstalling the
/// app does not hand out a fresh free allowance or a fresh trial. The limits themselves live in
/// `FreeTier` / `Limits` and can be changed from Remote Config.
@MainActor
final class UsageManager: ObservableObject {

    /// Run units spent today on the free plan.
    @Published private(set) var used: Int
    /// Run units spent today by a subscriber (Pro or trial). Only used for the fair-use cap.
    @Published private(set) var proUsed: Int
    /// Run units the free plan has spent on this device, in total.
    @Published private(set) var lifetimeUsed: Int
    /// Run units spent during free trials on this device, in total.
    @Published private(set) var trialUsed: Int
    /// Free runs this device got without watching a video (nothing could be shown).
    @Published private(set) var noAdUsed: Int
    /// Welcome runs this device got without watching a video.
    @Published private(set) var introUsed: Int

    private var day: String

    private static let snapshotKey = "usage.snapshot.v1"
    private static let legacyUsedKey = "usage.used.v2"
    private static let legacyProUsedKey = "usage.pro.used.v1"
    private static let legacyDayKey = "usage.day.v2"


    /// Everything that is stored. Kept as plain JSON so a later version can add fields freely.
    private struct Snapshot {
        var day: String
        var used = 0
        var proUsed = 0
        var lifetimeUsed = 0
        var trialUsed = 0
        var noAdUsed = 0
        var introUsed = 0

        init(day: String) {
            self.day = day
        }

        init?(data: Data?) {
            guard let data,
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let day = object["day"] as? String else { return nil }
            self.day = day
            used = max(0, object["used"] as? Int ?? 0)
            proUsed = max(0, object["proUsed"] as? Int ?? 0)
            lifetimeUsed = max(0, object["lifetimeUsed"] as? Int ?? 0)
            trialUsed = max(0, object["trialUsed"] as? Int ?? 0)
            noAdUsed = max(0, object["noAdUsed"] as? Int ?? 0)
            introUsed = max(0, object["introUsed"] as? Int ?? 0)
        }

        var data: Data? {
            let object: [String: Any] = [
                "day": day,
                "used": used,
                "proUsed": proUsed,
                "lifetimeUsed": lifetimeUsed,
                "trialUsed": trialUsed,
                "noAdUsed": noAdUsed,
                "introUsed": introUsed
            ]
            return try? JSONSerialization.data(withJSONObject: object)
        }
    }

    /// Two copies of the same counters (Keychain and UserDefaults) can differ when one write failed:
    /// the more recent day wins and totals never go backwards.
    private static func merged(_ first: Snapshot, _ second: Snapshot) -> Snapshot {
        var result = first.day >= second.day ? first : second
        if first.day == second.day {
            result.used = max(first.used, second.used)
            result.proUsed = max(first.proUsed, second.proUsed)
        }
        result.lifetimeUsed = max(first.lifetimeUsed, second.lifetimeUsed)
        result.trialUsed = max(first.trialUsed, second.trialUsed)
        result.noAdUsed = max(first.noAdUsed, second.noAdUsed)
        result.introUsed = max(first.introUsed, second.introUsed)
        return result
    }

    private static func loadSnapshot(today: String) -> Snapshot {
        let defaults = UserDefaults.standard
        let fromKeychain = Snapshot(data: KeychainStore.read(snapshotKey))
        let fromDefaults = Snapshot(data: defaults.data(forKey: snapshotKey))

        var snapshot: Snapshot
        if let fromKeychain, let fromDefaults {
            snapshot = merged(fromKeychain, fromDefaults)
        } else if let fromKeychain {
            snapshot = fromKeychain
        } else if let fromDefaults {
            snapshot = fromDefaults
        } else {
            // First launch of this version: carry over what the previous version counted today.
            snapshot = Snapshot(day: today)
            if defaults.string(forKey: legacyDayKey) == today {
                snapshot.used = max(0, defaults.integer(forKey: legacyUsedKey))
                snapshot.proUsed = max(0, defaults.integer(forKey: legacyProUsedKey))
                snapshot.lifetimeUsed = snapshot.used
            }
        }

        // A new day starts a fresh daily budget. Going back in time (device clock) never does.
        if today > snapshot.day {
            snapshot.day = today
            snapshot.used = 0
            snapshot.proUsed = 0
        }
        return snapshot
    }

    init() {
        let snapshot = Self.loadSnapshot(today: Self.dayStamp())
        day = snapshot.day
        used = snapshot.used
        proUsed = snapshot.proUsed
        lifetimeUsed = snapshot.lifetimeUsed
        trialUsed = snapshot.trialUsed
        noAdUsed = snapshot.noAdUsed
        introUsed = snapshot.introUsed
        persist()
    }


    // MARK: Free plan

    var dailyLimit: Int { FreeTier.dailyRunUnits }

    /// Units left on the free plan right now: what is left of today's budget, but never more than
    /// what is left of this device's total free allowance.
    var remaining: Int {
        max(0, min(dailyLimit - used, lifetimeRemaining))
    }

    /// Units left of the device-wide free allowance (practically endless when that limit is off).
    var lifetimeRemaining: Int {
        let cap = FreeTier.lifetimeRunUnits
        return cap > 0 ? max(0, cap - lifetimeUsed) : Int.max
    }

    /// True when the device-wide allowance, not today's budget, is what stops the next free run.
    var isLimitedByLifetime: Bool {
        FreeTier.lifetimeRunUnits > 0 && lifetimeRemaining <= max(0, dailyLimit - used)
    }

    func canAfford(_ cost: Int) -> Bool {
        rollIfNeeded()
        return remaining >= cost
    }

    func consume(_ cost: Int) {
        rollIfNeeded()
        used = min(dailyLimit, used + cost)
        lifetimeUsed += cost
        persist()
    }

    func refund(_ cost: Int) {
        used = max(0, used - cost)
        lifetimeUsed = max(0, lifetimeUsed - cost)
        persist()
    }

    /// A free run may go ahead without a video only a few times per device. This stops people who
    /// decline ads (or live where none are served) from getting endless runs that earn nothing.
    var canRunWithoutAd: Bool { noAdUsed < FreeTier.noAdRuns }

    func noteRunWithoutAd() {
        noAdUsed += 1
        persist()
    }

    /// The first free run(s) on a device skip the video. Nothing has earned the app anything yet,
    /// but a smooth first result is what makes people stay and, later, pay.
    var introRunAvailable: Bool { introUsed < FreeTier.introRuns }

    func noteIntroRun() {
        introUsed += 1
        persist()
    }


    // MARK: Subscribers

    /// Units a trial may still spend on this device (all trials together).
    var trialRemaining: Int { max(0, Limits.trialTotalUnits - trialUsed) }

    func proRemaining(limit: Int, trial: Bool = false) -> Int {
        let daily = max(0, limit - proUsed)
        return trial ? min(daily, trialRemaining) : daily
    }

    func proCanAfford(_ cost: Int, limit: Int, trial: Bool = false) -> Bool {
        rollIfNeeded()
        // A single run that costs more than the whole daily budget is still allowed once a day,
        // so a mis-set limit can never lock a subscriber out of a tool for good.
        guard max(0, limit - proUsed) >= min(cost, limit) else { return false }
        if trial {
            return trialRemaining >= min(cost, Limits.trialTotalUnits)
        }
        return true
    }

    func proConsume(_ cost: Int, trial: Bool = false) {
        rollIfNeeded()
        proUsed += cost
        if trial { trialUsed += cost }
        persist()
    }

    func proRefund(_ cost: Int, trial: Bool = false) {
        proUsed = max(0, proUsed - cost)
        if trial { trialUsed = max(0, trialUsed - cost) }
        persist()
    }

    /// What to tell a subscriber whose run was refused.
    func proLimitMessage(cost: Int, trial: Bool) -> String {
        if trial && trialRemaining < min(cost, Limits.trialTotalUnits) {
            if trialRemaining == 0 {
                return "You've used all the runs included in your trial. The full daily limit starts with your paid plan."
            }
            return "That run needs more than what's left of your trial. Try a smaller photo or a lighter tool."
        }
        return "You've reached today's Pro limit. \(resetText)."
    }


    // MARK: Day change

    func rollIfNeeded() {
        let today = Self.dayStamp()
        guard today > day else { return }
        day = today
        used = 0
        proUsed = 0
        persist()
    }

    var resetText: String {
        let calendar = Calendar.current
        guard let midnight = calendar.nextDate(after: Date(),
                                                matching: DateComponents(hour: 0, minute: 0, second: 0),
                                                matchingPolicy: .nextTime) else {
            return "Resets at midnight"
        }
        let seconds = max(60, Int(midnight.timeIntervalSinceNow))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "Resets in \(hours)h \(minutes)m"
        }
        return "Resets in \(minutes)m"
    }

    private func persist() {
        var snapshot = Snapshot(day: day)
        snapshot.used = used
        snapshot.proUsed = proUsed
        snapshot.lifetimeUsed = lifetimeUsed
        snapshot.trialUsed = trialUsed
        snapshot.noAdUsed = noAdUsed
        snapshot.introUsed = introUsed
        guard let data = snapshot.data else { return }
        UserDefaults.standard.set(data, forKey: Self.snapshotKey)
        KeychainStore.write(data, account: Self.snapshotKey)
    }

    /// "yyyy-MM-dd" in the device's time zone, always on the Gregorian calendar, so two stamps
    /// can be compared as plain strings.
    private static func dayStamp() -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let parts = calendar.dateComponents([.year, .month, .day], from: Date())
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let dayOfMonth = parts.day ?? 1
        let monthText = month < 10 ? "0\(month)" : "\(month)"
        let dayText = dayOfMonth < 10 ? "0\(dayOfMonth)" : "\(dayOfMonth)"
        return "\(year)-\(monthText)-\(dayText)"
    }
}
