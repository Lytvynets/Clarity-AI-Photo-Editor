
import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseRemoteConfig)
import FirebaseRemoteConfig
#endif

/// Values that can be changed from the Firebase console (Remote Config) without shipping an
/// app update: the Claid API key and the usage limits.
///
/// Every value is mirrored into UserDefaults after a successful fetch, so reads are instant and
/// thread-safe, the last known values keep working offline, and nothing breaks if Firebase is not
/// linked yet or `GoogleService-Info.plist` is missing (the built-in defaults below are used).
final class RemoteSettings: @unchecked Sendable {

    static let shared = RemoteSettings()

    enum IntKey: String, CaseIterable {
        case freeDailyUnits = "free_daily_units"
        case trialDailyUnits = "trial_daily_units"
        case proDailyUnits = "pro_daily_units"
        case costEnhance = "cost_enhance"
        case costBlur = "cost_blur"
        case costMagic = "cost_magic"
        case costCreate = "cost_create"
        case costAIExtend = "cost_ai_extend"
        case freeMaxInputSide = "free_max_input_side"

        /// Used until (or unless) the console provides a value.
        var fallback: Int {
            switch self {
            case .freeDailyUnits: return 4
            case .trialDailyUnits: return 10
            case .proDailyUnits: return 30
            case .costEnhance: return 2
            case .costBlur: return 2
            case .costMagic: return 3
            case .costCreate: return 3
            case .costAIExtend: return 2
            case .freeMaxInputSide: return 2048
            }
        }

        /// A typo in the console can never push a value outside this range.
        var allowed: ClosedRange<Int> {
            switch self {
            case .freeDailyUnits: return 1...20
            case .trialDailyUnits: return 3...200
            case .proDailyUnits: return 5...500
            case .costEnhance, .costBlur, .costMagic, .costCreate, .costAIExtend: return 1...10
            case .freeMaxInputSide: return 1024...4096
            }
        }
    }

    private static let claidKeyName = "claid_api_key"

    private let defaults = UserDefaults.standard
    private let lock = NSLock()
    private var finishedFirstFetch = false

    private func storageKey(_ name: String) -> String { "rc.v1." + name }


    func int(_ key: IntKey) -> Int {
        guard let text = defaults.string(forKey: storageKey(key.rawValue)),
              let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return key.fallback
        }
        return min(max(value, key.allowed.lowerBound), key.allowed.upperBound)
    }

    var claidAPIKey: String {
        let stored = defaults.string(forKey: storageKey(Self.claidKeyName)) ?? ""
        return stored.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    var hasFinishedFirstFetch: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finishedFirstFetch
    }

    private func markFinished() {
        lock.lock()
        finishedFirstFetch = true
        lock.unlock()
    }

    func start() {
        Task { await self.refresh() }
    }

    /// Fetches and activates the latest values. Regular calls respect Firebase's own throttling
    /// (1 hour in release builds); `force` skips it.
    @discardableResult
    func refresh(force: Bool = false) async -> Bool {
        #if canImport(FirebaseRemoteConfig)
        guard FirebaseBootstrap.isConfigured else {
            markFinished()
            return false
        }
        let ok = await fetch(force: force)
        markFinished()
        return ok
        #else
        markFinished()
        return false
        #endif
    }

    /// Waits (briefly) for the first fetch — only used when no API key is available yet.
    func waitForFirstFetch(timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !hasFinishedFirstFetch, Date() < deadline {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// Called when Claid rejects the key: pulls a fresh copy and reports whether the key changed,
    /// so a rotated key reaches existing installs without an App Store update.
    func refreshClaidKeyAfterRejection() async -> Bool {
        let before = ClaidKey.current
        await refresh(force: true)
        return ClaidKey.current != before
    }


    #if canImport(FirebaseRemoteConfig)
    private func fetch(force: Bool) async -> Bool {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = force ? 0 : 3600
        #endif
        remoteConfig.configSettings = settings

        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            remoteConfig.fetchAndActivate { [weak self] _, error in
                if let error {
                    print("⚠️ Remote Config fetch failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                    return
                }
                self?.mirror(from: remoteConfig)
                continuation.resume(returning: true)
            }
        }
    }

    /// Copies what the console actually defines into local storage. A parameter that was deleted
    /// from the console is removed locally too, so it falls back to the built-in default.
    private func mirror(from remoteConfig: RemoteConfig) {
        var names = IntKey.allCases.map { $0.rawValue }
        names.append(Self.claidKeyName)

        for name in names {
            let value = remoteConfig.configValue(forKey: name)
            let text: String? = value.stringValue
            if value.source == .remote, let text, !text.isEmpty {
                defaults.set(text, forKey: storageKey(name))
            } else {
                defaults.removeObject(forKey: storageKey(name))
            }
        }
        #if DEBUG
        print("☁️ Remote Config applied · Claid key from \(ClaidKey.sourceName)")
        #endif
    }
    #endif
}


/// Where the Claid API key comes from: Remote Config first, then the local `Secrets.swift`
/// (kept as an offline / first-launch fallback).
enum ClaidKey {

    static var current: String {
        let remote = RemoteSettings.shared.claidAPIKey
        if !remote.isEmpty { return remote }
        return Secrets.claidAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var sourceName: String {
        RemoteSettings.shared.claidAPIKey.isEmpty ? "local Secrets.swift" : "Remote Config"
    }

    /// Makes sure a key exists before the first request. Returns immediately when one is already
    /// cached or compiled in.
    static func prepare() async {
        guard current.isEmpty else { return }
        await RemoteSettings.shared.waitForFirstFetch(timeout: 6)
    }
}
