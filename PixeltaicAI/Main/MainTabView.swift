//
//  TabView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 23.11.2024.
//

import SwiftUI

struct MainTabView: View {
    
    @StateObject var localFilesManager = LocalFilesManager()
    @StateObject var tabSelection = TabSelection()
    @StateObject var notificationManager = NotificationManager()
    @EnvironmentObject var inAppPurchaseManager: InAppPurchaseManager
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        
        ZStack {
            
            TabView(selection: $tabSelection.selectedTab) {
                HomeScreen()
                    .preferredColorScheme(.dark)
                    .environmentObject(localFilesManager)
                    .environmentObject(tabSelection)
                    .environmentObject(notificationManager)
                    .environmentObject(inAppPurchaseManager)
                    .environmentObject(onboardingViewModel)
                
                    .tabItem {
                        VStack{
                            Image("magic-wand 1").renderingMode(.template)
                        }
                    }.tag(0)
                
                HistoryScreen()
                    .environmentObject(localFilesManager)
                    .tabItem {
                        VStack {
                            Image("history-3 1").renderingMode(.template)
                        }
                    }.tag(1)
                
                SettingsScreen()
                    .environmentObject(inAppPurchaseManager)
                    .tabItem {
                        VStack {
                            Image("settings-2 1").renderingMode(.template)
                        }
                    }.tag(2)
                
            }.accentColor(Color(.backgroundGradient))
               
            
            if notificationManager.showNotification {
                VStack {
                    CustomNotification()
                        .padding(.horizontal)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}


class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 0
}


class NotificationManager: NSObject, ObservableObject {
    
    @Published var showNotification = false
    
    func showCustomNotification() {
   
        withAnimation {
            self.showNotification = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                self.showNotification = false
            }
        }
    }
}
