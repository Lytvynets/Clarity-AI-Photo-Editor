//
//  SettingsScreen.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 22.10.2024.
//

import SwiftUI
import StoreKit

struct SettingsLinks {
    let otherAppsUrl = "https://apps.apple.com/us/developer/vladyslav-lytvynets/id1660079103"
    let privacyPolicyUrl = "https://www.termsfeed.com/live/aafdb059-dfc0-47e0-8983-d44d87067c5c"
    let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    let appInStoreUrl = "https://apps.apple.com/app/pixeltaicai/id6737229595"
}

struct SettingsScreen: View {
    
    private var settingsLinks = SettingsLinks()
    @State private var showShareSheet = false
    @Environment(\.openURL) var openURL
    @EnvironmentObject var inAppPurchaseManager: InAppPurchaseManager
    
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing)
                .ignoresSafeArea()
                .navigationTitle("Settings")
                .sheet(isPresented: $showShareSheet, content: {
                    if let url = URL(string: settingsLinks.appInStoreUrl) {
                        ShareSheetURL(activityItems: [url])
                    }
                })
                
                List {
                    
                    SettingsCell(cellText: "Rate us")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 15, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            requestReview()
                        }
                    
                    SettingsCell(cellText: "Share")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            showShareSheet = true
                        }
                    
                    SettingsCell(cellText: "Other apps")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            if let url = URL(string: settingsLinks.otherAppsUrl) {
                                UIApplication.shared.open(url, options: [:])
                            }
                        }
                    
                    SettingsCell(cellText: "Privacy policy")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            if let url = URL(string: settingsLinks.privacyPolicyUrl) {
                                UIApplication.shared.open(url, options: [:])
                            }
                        }
                    
                    SettingsCell(cellText: "Terms of Use")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            if let url = URL(string: settingsLinks.termsOfUseUrl) {
                                UIApplication.shared.open(url, options: [:])
                            }
                        }
                    
                    SettingsCell(cellText: "Restore")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            Task {
                                await inAppPurchaseManager.restorePurchases()
                            }
                        }
                    
                    SettingsCell(cellText: "Feedback")
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 8, trailing: 15))
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            let email = "vladlytvynets7@gmail.com"
                            let subject = ""
                            let body = ""
                            
                            if let url = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)") {
                                openURL(url)
                            }
                        }
                }.listStyle(.plain)
            }
        }
    }
    
    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

#Preview {
    SettingsScreen()
}
