

import Foundation


enum AppLinks {
    static let appStoreID = "6737229595"
    static let appStore = "https://apps.apple.com/app/pixeltaicai/id6737229595"
    static let writeReview = "https://apps.apple.com/app/id6737229595?action=write-review"
    static let otherApps = "https://apps.apple.com/us/developer/vladyslav-lytvynets/id1660079103"
    static let privacyPolicy = "https://docs.google.com/document/d/1nrHTQEhCxrHxuI1yu1czkiWEXy1f4tlf/edit?usp=share_link&ouid=114599015370342281433&rtpof=true&sd=true"
    static let termsOfUse = "https://docs.google.com/document/d/1T8RrhbAt8wd1-zku9nJLIZiOjDi3Ie4O/edit?usp=share_link&ouid=114599015370342281433&rtpof=true&sd=true"
    static let manageSubscriptions = "https://apps.apple.com/account/subscriptions"
}


enum ProductID {
    static let weeklyTrial = "3.days.free.trai.weekly.pixeltaic.ai"
    static let weekly = "weekly.subscription.pixeltaic.ai"
    static let monthly = "monthly.subscription.pixeltaic.ai"
    static let yearly = "yearly.subscription.pixeltaic.ai"
    static let all: [String] = [yearly, monthly, weekly, weeklyTrial]
}


enum FreeTier {
    static let dailyRunUnits = 5
    static let maxUpscaleFree = 2
    static let generateImagesFree = 1
    static let generateImagesPro = 4
    static let watermarkEnabled = true
    static let watermarkText = "Clarity: AI Photo Editor"
    static let allowRunWhenAdUnavailable = true
}


enum AdConfig {
    static let testBanner = "ca-app-pub-4749079164629106/4520100368"
    static let testRewarded = "ca-app-pub-4749079164629106/6913320256"

    static let liveBanner = "ca-app-pub-4749079164629106/4520100368"
    static let liveRewarded = "ca-app-pub-4749079164629106/6913320256"

    static var bannerID: String {
        #if DEBUG
        return testBanner
        #else
        return liveBanner.isEmpty ? testBanner : liveBanner
        #endif
    }

    static var rewardedID: String {
        #if DEBUG
        return testRewarded
        #else
        return liveRewarded.isEmpty ? testRewarded : liveRewarded
        #endif
    }
}


enum APIConfig {
    static let directHost = "https://api.claid.ai"
    static let editUploadPath = "/v1-beta1/image/edit/upload"
    static let generatePath = "/v1-beta1/image/generate"
    static let aiEditPath = "/v1/image/ai-edit"
}
