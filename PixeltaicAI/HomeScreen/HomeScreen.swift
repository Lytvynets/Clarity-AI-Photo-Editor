//
//  ContentView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 22.10.2024.
//

import SwiftUI

struct HomeScreen: View {
    
    @State var isPresentedEditingScreen = false
    @State var isPresentedGeneratingScreen = false
    @State private var launchCountHomeScreen = 0
    @State private var isPresentedSpecialOfferPaywall = false
    @StateObject var editingViewMod = EditingViewModObserver()
    
    @EnvironmentObject var localFilesManager: LocalFilesManager
    @EnvironmentObject var tabSelection: TabSelection
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var inAppPurchaseManager: InAppPurchaseManager
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ]
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing)
                .ignoresSafeArea()
                .navigationTitle("Pixeltaic AI")
                
                
                VStack {
                    
                    ScrollView {
                        
                        LazyVGrid(columns: columns) {
                            
                            ForEach(0...5, id: \.self) { index in
                                
                                ZStack {
                                    
                                    BlurView(style: .dark).frame(width: UIScreen.main.bounds.width / 2.6,
                                                                 height: UIScreen.main.bounds.width / 2.6)
                                    .opacity(0.7)
                                    .blur(radius: 1)
                                    .cornerRadius(25)
                                    .padding(.top)
                                    
                                    if index == 0 {
                                        VStack(spacing: 15) {
                                            
                                            Image("restorations")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 65, height: 65)
                                                .padding(.top, 15)
                                            
                                            Text("Restorations")
                                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                                        }.onTapGesture {
                                            editingViewMod.editingViewMod = .restorations
                                            isPresentedEditingScreen = true
                                        }.fullScreenCover(isPresented: $isPresentedEditingScreen) {
                                            EditingView()
                                                .environmentObject(editingViewMod)
                                        }
                                        
                                    }else if index == 1 {
                                        VStack(spacing: 15) {
                                            
                                            Image("resizing")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 55, height: 55)
                                                .padding(.top, 15)
                                            
                                            Text("Resizing")
                                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                                        }.onTapGesture {
                                            editingViewMod.editingViewMod = .resizing
                                            isPresentedEditingScreen = true
                                            
                                        }.fullScreenCover(isPresented: $isPresentedEditingScreen) {
                                            EditingView()
                                                .environmentObject(editingViewMod)
                                        }
                                        
                                    }else if index == 2 {
                                        VStack(spacing: 15) {
                                            
                                            Image("padding")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 45, height: 45)
                                                .padding(.top, 15)
                                            
                                            Text("Padding")
                                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                                        }.onTapGesture {
                                            editingViewMod.editingViewMod = .padding
                                            isPresentedEditingScreen = true
                                        }.fullScreenCover(isPresented: $isPresentedEditingScreen) {
                                            EditingView()
                                                .environmentObject(editingViewMod)
                                                .environmentObject(localFilesManager)
                                        }
                                        
                                    }else if index == 3 {
                                        VStack(spacing: 15) {
                                            
                                            Image("Group 7")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 65, height: 65)
                                                .padding(.top, 15)
                                            
                                            Text("Color Adjustments")
                                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                                        }.onTapGesture {
                                            editingViewMod.editingViewMod = .colorAdjustments
                                            isPresentedEditingScreen = true
                                        }.fullScreenCover(isPresented: $isPresentedEditingScreen) {
                                            EditingView()
                                                .environmentObject(editingViewMod)
                                        }
                                        
                                    }else if index == 4 {
                                        VStack(spacing: 15) {
                                            
                                            Image("Group 10")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 45, height: 45)
                                                .padding(.top, 15)
                                            
                                            Text("Image Generation")
                                            
                                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                                        }.onTapGesture {
                                            isPresentedGeneratingScreen = true
                                        }.fullScreenCover(isPresented: $isPresentedGeneratingScreen) {
                                            GeneratingView()
                                                .environmentObject(localFilesManager)
                                                .environmentObject(tabSelection)
                                                .environmentObject(notificationManager)
                                        }
                                        
                                    }else if index == 5 {
                                        VStack(spacing: 15) {
                                            
                                            Image("Vector")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 45, height: 45)
                                                .padding(.top, 15)
                                            
                                            Text("Background ")
                                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                                        }.onTapGesture {
                                            editingViewMod.editingViewMod = .background
                                            DispatchQueue.main.async {
                                                isPresentedEditingScreen = true
                                            }
                                        }.fullScreenCover(isPresented: $isPresentedEditingScreen) {
                                            EditingView()
                                                .environmentObject(editingViewMod)
                                        }
                                    }
                                }
                            }
                        }
                    }.scrollIndicators(.hidden)
                }.padding(.horizontal)
            }
        }.onAppear {
            
            switch UserDefaults.standard.bool(forKey: "isPremiumUser") {
            case true:
                print("is Premium User")
            case false:
                print("is not premium user")
                
                if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                    if !onboardingViewModel.showOnboarding {
                        
                        launchCountHomeScreen += 1
                        if launchCountHomeScreen <= 1 {
                            isPresentedSpecialOfferPaywall = true
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentedSpecialOfferPaywall) {
            Paywall()
                .environmentObject(inAppPurchaseManager)
        }
    }
}

#Preview {
    HomeScreen()
}
