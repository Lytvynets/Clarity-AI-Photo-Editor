
import Foundation

@MainActor
final class UsageManager: ObservableObject {

    /// Run units spent today on the free plan.
    @Published private(set) var used: Int
    /// Run units spent today by a subscriber (Pro or trial). Only used for the fair-use cap.
    @Published private(set) var proUsed: Int

    private let usedKey = "usage.used.v2"
    private let proUsedKey = "usage.pro.used.v1"
    private let dayKey = "usage.day.v2"

    init() {
        let defaults = UserDefaults.standard
        let today = Self.dayStamp()
        if defaults.string(forKey: dayKey) != today {
            defaults.set(today, forKey: dayKey)
            defaults.set(0, forKey: usedKey)
            defaults.set(0, forKey: proUsedKey)
            used = 0
            proUsed = 0
        } else {
            used = defaults.integer(forKey: usedKey)
            proUsed = defaults.integer(forKey: proUsedKey)
        }
    }


    var dailyLimit: Int { FreeTier.dailyRunUnits }
    var remaining: Int { max(0, dailyLimit - used) }

    func canAfford(_ cost: Int) -> Bool {
        rollIfNeeded()
        return remaining >= cost
    }

    func consume(_ cost: Int) {
        rollIfNeeded()
        used = min(dailyLimit, used + cost)
        persist()
    }

    func refund(_ cost: Int) {
        used = max(0, used - cost)
        persist()
    }


    func proRemaining(limit: Int) -> Int { max(0, limit - proUsed) }

    func proCanAfford(_ cost: Int, limit: Int) -> Bool {
        rollIfNeeded()
        // A single run that costs more than the whole daily budget is still allowed once a day,
        // so a mis-set limit can never lock a subscriber out of a tool for good.
        return proRemaining(limit: limit) >= min(cost, limit)
    }

    func proConsume(_ cost: Int) {
        rollIfNeeded()
        proUsed += cost
        persist()
    }

    func proRefund(_ cost: Int) {
        proUsed = max(0, proUsed - cost)
        persist()
    }


    func rollIfNeeded() {
        let today = Self.dayStamp()
        if UserDefaults.standard.string(forKey: dayKey) != today {
            UserDefaults.standard.set(today, forKey: dayKey)
            used = 0
            proUsed = 0
            persist()
        }
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
        UserDefaults.standard.set(used, forKey: usedKey)
        UserDefaults.standard.set(proUsed, forKey: proUsedKey)
    }

    private static func dayStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
