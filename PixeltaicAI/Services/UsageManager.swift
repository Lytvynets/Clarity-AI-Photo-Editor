

import Foundation

@MainActor
final class UsageManager: ObservableObject {

    @Published private(set) var used: Int

    private let usedKey = "usage.used.v2"
    private let dayKey = "usage.day.v2"

    init() {
        let defaults = UserDefaults.standard
        let today = Self.dayStamp()
        if defaults.string(forKey: dayKey) != today {
            defaults.set(today, forKey: dayKey)
            defaults.set(0, forKey: usedKey)
            used = 0
        } else {
            used = defaults.integer(forKey: usedKey)
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

    func rollIfNeeded() {
        let today = Self.dayStamp()
        if UserDefaults.standard.string(forKey: dayKey) != today {
            UserDefaults.standard.set(today, forKey: dayKey)
            used = 0
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
    }

    private static func dayStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
