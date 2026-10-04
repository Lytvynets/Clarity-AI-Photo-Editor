

import SwiftUI

struct MainTabView: View {

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var ads: AdManager
    @EnvironmentObject private var library: LibraryStore

    @Namespace private var tabNamespace

    var body: some View {
        ZStack {
            StudioView()
                .tabVisibility(router.tab == .studio)
            LibraryView()
                .tabVisibility(router.tab == .library)
            SettingsView()
                .tabVisibility(router.tab == .settings)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .fullScreenCover(item: $router.destination) { destination in
            destinationView(destination)
        }
    }


    @ViewBuilder
    private func destinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .editor(_, let request):
            EditorView(request: request)
                .environmentObject(subscription)
                .environmentObject(usage)
                .environmentObject(ads)
                .environmentObject(library)
                .environmentObject(router)
        case .create:
            CreateView()
                .environmentObject(subscription)
                .environmentObject(usage)
                .environmentObject(ads)
                .environmentObject(library)
                .environmentObject(router)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            AdBanner()
            tabBar
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
        .padding(.top, 8)
        .background(
            LinearGradient(colors: [Theme.bg0.opacity(0), Theme.bg0.opacity(0.92)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    guard router.tab != tab else { return }
                    Haptics.select()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                        router.tab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(router.tab == tab ? .white : Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if router.tab == tab {
                            Capsule()
                                .fill(Theme.brandGradient)
                                .shadow(color: Theme.violet.opacity(0.5), radius: 10, x: 0, y: 4)
                                .matchedGeometryEffect(id: "tab-indicator", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}

private extension View {
    func tabVisibility(_ visible: Bool) -> some View {
        self
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
            .accessibilityHidden(!visible)
            .zIndex(visible ? 1 : 0)
    }
}
