

import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSizeFor(cgSize: CGSize(width: 320, height: 50)))
        banner.adUnitID = AdConfig.bannerID
        banner.rootViewController = UIApplication.shared.topViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
#else
struct BannerAdView: View {
    var body: some View { Color.clear }
}
#endif

struct AdBanner: View {
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var ads: AdManager

    var body: some View {
        Group {
            if !subscription.isPro && ads.adsAllowed {
                BannerAdView()
                    .frame(width: 320, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Theme.stroke, lineWidth: 1)
                    )
                    .padding(.top, 6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: ads.adsAllowed)
        .animation(.easeInOut(duration: 0.3), value: subscription.isPro)
    }
}
