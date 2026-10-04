
import SwiftUI

@main
struct PixeltaicAIApp: App {

    @StateObject private var subscription = SubscriptionManager()
    @StateObject private var usage = UsageManager()
    @StateObject private var ads = AdManager()
    @StateObject private var library = LibraryStore()
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscription)
                .environmentObject(usage)
                .environmentObject(ads)
                .environmentObject(library)
                .environmentObject(router)
                .preferredColorScheme(.dark)
        }
    }
}
