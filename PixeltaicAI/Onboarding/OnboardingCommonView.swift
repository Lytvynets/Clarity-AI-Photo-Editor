//
//  OnboardingView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 18.11.2024.
//

import SwiftUI

struct OnboardingCommonView: View {
    
    @State var currentIndex = 0
    @State var showPaywall = false
    @EnvironmentObject var inAppPurchaseManager: InAppPurchaseManager
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    
    var body: some View {
        
        TabView(selection: $currentIndex) {
            
            if showPaywall {
                Paywall()
                    .environmentObject(inAppPurchaseManager)
            }else {
                OnboardingView(onboardingItem: onboardingViewModel.onboardingItems[currentIndex], currentIndex: currentIndex, onNext: { nextPage() })
            }
        }.ignoresSafeArea()
    }
    
    private func nextPage() {
        withAnimation {
            if currentIndex < 3 {
                currentIndex += 1
            }else{
                showPaywall = true
            }
        }
    }
}


#Preview {
    OnboardingCommonView()
        .environmentObject(InAppPurchaseManager())
}


struct OnboardingView: View {
    
    var onboardingItem: OnboardingItemModel
    var currentIndex: Int
    var onNext: () -> Void
    
    var body: some View {
        
        
        ZStack {
            
            if currentIndex == 3 {
                Color(.backgroundOnboarding)
            }
            
            VStack {
                
                if currentIndex != 3 && currentIndex != 2 {
                    Image(onboardingItem.imageName)
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.6)
                        .aspectRatio(contentMode: .fit)
                }
                
                if currentIndex == 3 {
                    
                    Image(onboardingItem.imageName)
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.2)
                        .aspectRatio(contentMode: .fit)
                }
                
                
                if currentIndex == 2 {
                    
                    Image(onboardingItem.imageName)
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 1.4)
                        .aspectRatio(contentMode: .fit)
                }
                
                Spacer()
            }
            
            VStack {
                
                Spacer()
                
                VStack {
                    
                    HStack {
                        
                        ForEach(0..<5) { item in
                            
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: item == currentIndex ? 27 : 18, height: 7)
                                .foregroundStyle(item == currentIndex ? .buttonGratient1 : .gray )
                                .opacity(item == currentIndex ? 1.0 : 0.4)
                        }
                    }.padding(.top, 40)
                    
                    
                    Text(onboardingItem.title)
                        .font(.custom("Lato-Bold", size: 24))
                        .padding(.top, 30)
                    
                    Text(onboardingItem.subTitle)
                    
                        .font(.custom("Lato-Light", size: 16))
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onNext()
                        
                    }label: {
                        Text("Next")
                            .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .padding()
                        
                    }.background(
                        LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding()
                    .padding(.bottom, 30)
                }
                .frame(width: UIScreen.main.bounds.width)
                .background(
                    LinearGradient(gradient: Gradient(colors: [.onbViewGradient1, .onbViewGradient2]), startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 40))
            }.ignoresSafeArea()
            
        }
        .ignoresSafeArea()
    }
}

