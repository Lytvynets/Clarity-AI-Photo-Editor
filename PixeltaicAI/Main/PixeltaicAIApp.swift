//
//  PixeltaicAIApp.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 22.10.2024.
//

import SwiftUI

@main
struct PixeltaicAIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var hasSeenOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State var appIsActive = false
    @StateObject var inAppPurchaseManager = InAppPurchaseManager()
    @StateObject var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            
            if !appIsActive {
                LaunchScreen()
                    .onAppear {
                        inAppPurchaseSetup()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            appIsActive = true
                        }
                    }
            } else {
                
                
                if hasSeenOnboarding {
                    MainTabView()
                        .environmentObject(onboardingViewModel)
                        .environmentObject(inAppPurchaseManager)
                    
                } else {
                    MainTabView()
                        .environmentObject(onboardingViewModel)
                        .environmentObject(inAppPurchaseManager)
                        .onAppear {
                            onboardingViewModel.showOnboarding = true
                        }
                        .fullScreenCover(isPresented: $onboardingViewModel.showOnboarding) {
                            OnboardingCommonView()
                                .environmentObject(onboardingViewModel)
                                .environmentObject(inAppPurchaseManager)
                        }
                        .onAppear {
                            UserDefaults.standard.setValue(true, forKey: "hasSeenOnboarding")
                        }
                }
            }
        }
    }
    
    
    private func inAppPurchaseSetup() {
        Task {
            await inAppPurchaseManager.fetchProducts()
        }
        
        Task {
            await inAppPurchaseManager.listenForTransactionUpdates()
        }
    }
}
