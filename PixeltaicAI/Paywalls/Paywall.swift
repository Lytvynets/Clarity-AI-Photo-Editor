//
//  Paywall.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 18.11.2024.
//

import SwiftUI

enum SubscriptionPlan {
    case monthly
    case weekly
    case yearly
}


struct Paywall: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var inAppPurchaseManager: InAppPurchaseManager
    private var productsID = ProductsID()
    private var settingsLinks = SettingsLinks()
    @State var subscriptionPlan: SubscriptionPlan = .weekly
    @State var presentErrorAlert = false
    @State var selectedProductId = ""
    @State var priceOfWeekly = ""
    @State var priceOfMonthly = ""
    @State var priceOfYearly = ""
    @State var pricePerWeekMonthly = ""
    @State var pricePerWeekYearly = ""
    
    var body: some View {
        
        ZStack {
            
            Color(.backgroundOnboarding)
                .ignoresSafeArea()
            
            
            VStack {
                Image("line-12")
                
                Spacer()
            }
            
            VStack {
                
                Image("Group 1000003580")
                    .resizable()
                    .frame(width: UIScreen.main.bounds.width / 1.2, height: UIScreen.main.bounds.height / 3.5)
                    .aspectRatio(contentMode: .fit)
                    .padding(.top)
                
                Spacer()
                
            }
            .padding(.top, 30)
            
            VStack {
                
                HStack {
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    }label: {
                        Image("close 1")
                            .colorMultiply(.white)
                    }
                    
                }
                .padding()
                .padding(.horizontal, 10)
                
                Spacer()
            }
            
            VStack {
                
                Spacer()
                
                VStack {
                    
                    Text("Pixeltaic AI")
                        .font(.custom("Lato-Bold", size: 24))
                        .padding(.top)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Pixeltaic AI is your ultimate \nAI-powered photo editing tool")
                        .font(.custom("Lato-lifht", size: 16))
                        .padding(.top, 5)
                        .foregroundStyle(.labelGray)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                    Image("Frame 135")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal)
                    
                    HStack {
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            subscriptionPlan = .monthly
                            selectedProductId = productsID.monthly
                        }label: {
                            VStack {
                                
                                Text("    Popular           ")
                                    .padding(10)
                                    .foregroundStyle(subscriptionPlan == .monthly ? .buttonGratient1 : .white)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.small))
                                    .background(subscriptionPlan == .monthly ? .white : .buttonGratient1)
                                    .cornerRadius(20)
                                    .padding(.top, 5)
                                    .padding(.horizontal, 7)
                                
                                Text("Monthly")
                                    .foregroundStyle(subscriptionPlan == .monthly ? .white : .white)
                                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.paywallSubtitle))
                                    .padding(.top)
                                
                                Text("\(priceOfMonthly)$")
                                    .foregroundStyle(subscriptionPlan == .monthly ? .white : .buttonGratient1)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.paywallPrice))
                                    .padding(.bottom, 5)
                                
                                Text("\(pricePerWeekMonthly)$/week")
                                    .foregroundStyle(subscriptionPlan == .monthly ? .white : .white)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.paywallPrice2))
                                    .padding(.bottom, 15)
                            }   .frame(width: UIScreen.main.bounds.width / 3.5)
                                .background(subscriptionPlan == .monthly ? LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.backgroundGray]),startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(25)
                        }
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            subscriptionPlan = .weekly
                            selectedProductId = productsID.freeTrailWeekly
                        }label: {
                            
                            VStack {
                                
                                Text(inAppPurchaseManager.trialIsUsed ? "    Weekly           " : "3-day Free Trail")
                                    .padding(10)
                                    .foregroundStyle(subscriptionPlan == .weekly ? .buttonGratient1 : .white)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.small))
                                    .background(subscriptionPlan == .weekly ? .white : .buttonGratient1)
                                    .cornerRadius(20)
                                    .padding(.top, 5)
                                    .padding(.horizontal, 7)
                                    .multilineTextAlignment(.center)
                                
                                Text("Weekly")
                                    .foregroundStyle(subscriptionPlan == .weekly ? .white : .white)
                                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                                    .padding(.top, 10)
                                
                                Text("\(priceOfWeekly)$")
                                    .foregroundStyle(subscriptionPlan == .weekly ? .white : .buttonGratient1)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.paywallPrice))
                                    .padding(.bottom, 5)
                                
                                Text("\(priceOfWeekly)$/week")
                                    .foregroundStyle(subscriptionPlan == .weekly ? .white : .white)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.paywallPrice2))
                                    .padding(.bottom, 15)
                            }
                            .background(subscriptionPlan == .weekly ? LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.backgroundGray]),startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(25)
                        }
                        
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            subscriptionPlan = .yearly
                            selectedProductId = productsID.yearly
                        }label: {
                            
                            VStack {
                                
                                Text("     71% OFF     ")
                                    .padding(10)
                                    .foregroundStyle(subscriptionPlan == .yearly ? .buttonGratient1 : .white)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.small))
                                    .background(subscriptionPlan == .yearly ? .white : .buttonGratient1)
                                    .cornerRadius(20)
                                    .padding(.top, 5)
                                    .padding(.horizontal, 7)
                                
                                Text("Yearly")
                                    .foregroundStyle(subscriptionPlan == .yearly ? .white : .white)
                                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.paywallSubtitle))
                                    .padding(.top, 10)
                                
                                Text("\(priceOfYearly)$")
                                    .foregroundStyle(subscriptionPlan == .yearly ? .white : .buttonGratient1)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.paywallPrice))
                                    .padding(.bottom, 5)
                                
                                Text("\(pricePerWeekYearly)$/week")
                                    .foregroundStyle(subscriptionPlan == .yearly ? .white : .white)
                                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.paywallPrice2))
                                    .padding(.bottom, 15)
                            }
                            .frame(width: UIScreen.main.bounds.width / 3.5)
                            .background(subscriptionPlan == .yearly ? LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.backgroundGray]),startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(25)
                        }
                        
                    }.padding()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        Task {
                            if let product = inAppPurchaseManager.products.first(where: {$0.id == selectedProductId }) {
                                await inAppPurchaseManager.purchase(product) { result in
                                    switch result {
                                    case .success(_):
                                        dismiss()
                                    case .failure(_):
                                        presentErrorAlert = true
                                    }
                                }
                            }
                        }
                    }label: {
                        Text("Continue")
                            .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .padding()
                        
                    }.background(
                        LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    
                    .padding(.top, 10)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    
                    HStack {
                        
                        Button {
                            if let url = URL(string: settingsLinks.termsOfUseUrl) {
                                UIApplication.shared.open(url, options: [:])
                            }
                        }label: {
                            Text("Terms of Use")
                                .font(.custom("Lato-Light", size: 11))
                                .foregroundStyle(.labelGray)
                        }.padding(.horizontal)
                        
                        Button {
                            Task {
                                await inAppPurchaseManager.restorePurchases()
                            }
                        }label: {
                            Text("Restore")
                                .font(.custom("Lato-Light", size: 11))
                                .foregroundStyle(.labelGray)
                        }.padding(.horizontal, 25)
                        
                        Button {
                            if let url = URL(string: settingsLinks.privacyPolicyUrl) {
                                UIApplication.shared.open(url, options: [:])
                            }
                        }label: {
                            Text("Privacy policy")
                                .font(.custom("Lato-Light", size: 11))
                                .foregroundStyle(.labelGray)
                        }.padding(.horizontal)
                        
                    }.padding(.bottom, 24)
                    
                    
                }
                .frame(width: UIScreen.main.bounds.width)
                .background(
                    LinearGradient(gradient: Gradient(colors: [.onbViewGradient1, .onbViewGradient2]), startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedRectangle(cornerRadius: 40))
                
            }
            .ignoresSafeArea()
            
            if presentErrorAlert {
                ErrorAlert(presentAlert: $presentErrorAlert, textAlert: "Something went wrong")
            }
            
        }
        .task {
            let trialAvailable = await inAppPurchaseManager.isTrialAvailable(for: "3.days.free.trai.weekly.pixeltaic.ai")
            
            if trialAvailable {
                inAppPurchaseManager.trialIsUsed = false
                selectedProductId = "3.days.free.trai.weekly.pixeltaic.ai"
                print("✅ Є тріал")
            } else {
                inAppPurchaseManager.trialIsUsed = true
                selectedProductId = "weekly.subscription.pixeltaic.ai"
                print("❌ Тріал вже використано або недоступний")
            }
        }
        .onAppear {
            
            priceOfMonthly = inAppPurchaseManager.getPrice(productID: productsID.monthly, products: inAppPurchaseManager.products)
            priceOfYearly = inAppPurchaseManager.getPrice(productID: productsID.yearly, products: inAppPurchaseManager.products)
            pricePerWeekMonthly = pricePerWeek(price: priceOfMonthly, divide: 4)
            pricePerWeekYearly = pricePerWeek(price: priceOfYearly, divide: 52)
            
            if let number = Double(inAppPurchaseManager.getPrice(productID: productsID.freeTrailWeekly, products: inAppPurchaseManager.products)) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 2
                
                if let formattedString = formatter.string(from: NSNumber(value: number)) {
                    print(formattedString)
                    priceOfWeekly = formattedString
                }
            }
        }
    }
    
    
    func pricePerWeek(price: String, divide: Double ) -> String {
        if let number = Double(price) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
            
            if let formattedString = formatter.string(from: NSNumber(value: number / divide)) {
                print(formattedString)
                return formattedString
            }
        }
        return "-"
    }
}


#Preview {
    Paywall()
        .environmentObject(InAppPurchaseManager())
}
