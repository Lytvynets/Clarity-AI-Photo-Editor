//
//  InAppPurchaseManager.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 10.12.2024.
//

import Foundation
import StoreKit

struct ProductsID {
    let weekly = "weekly.subscription.pixeltaic.ai"
    let freeTrailWeekly = "3.days.free.trai.weekly.pixeltaic.ai"
    let monthly = "monthly.subscription.pixeltaic.ai"
    let yearly = "yearly.subscription.pixeltaic.ai"
}


class InAppPurchaseManager: ObservableObject {
    
    @Published var trialIsUsed = false
    @Published var products: [Product] = []
    private var productsID = ProductsID()
    
    
    
    func fetchProducts() async {
        do {
            
            let productIDs: Set<String> = [productsID.monthly,
                                           productsID.weekly,
                                           productsID.yearly,
                                           productsID.freeTrailWeekly]
            
            let products = try await Product.products(for: productIDs)
            DispatchQueue.main.async {
                self.products = products
                for i in products {
                    print("products \(i.id)")
                    Task {
                        switch await self.checkSubscriptionStatus(for: i.id) {
                        case true:
                            UserDefaults.standard.set(true, forKey: "isPremiumUser")
                        case false:
                            if !UserDefaults.standard.bool(forKey: "isPremiumUser") {
                                UserDefaults.standard.set(false, forKey: "isPremiumUser")
                            }
                        }
                    }
                }
                print(" завантаження продуктів")
            }
        } catch {
            print("Помилка завантаження продуктів: \(error)")
        }
    }
    
    
    @MainActor
    func isTrialAvailable(for productId: String) async -> Bool {
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                print("⚠️ Продукт з ID \(productId) не знайдено")
                return false
            }
            
            guard let subscription = product.subscription else {
                print("⚠️ Продукт не є підпискою")
                return false
            }
            
            // Отримати пробну пропозицію
            if let introOffer = subscription.introductoryOffer {
                // Перевірити eligibility (чи доступний тріал)
                let eligibility = await product.subscription?.isEligibleForIntroOffer ?? false
                return eligibility
            } else {
                // Взагалі немає тріалу
                return false
            }
            
        } catch {
            print("❌ Помилка при перевірці тріалу: \(error)")
            return false
        }
    }
    
    
    func purchase(_ product: Product, completion: @escaping (Result<Bool, Error>) -> Void) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("Покупка успішна: \(transaction.productID)")
                    UserDefaults.standard.set(true, forKey: "isPremiumUser")
                    completion(.success(true))
                    await transaction.finish()
                case .unverified(_, let error):
                    print("Невірна покупка: \(error)")
                    completion(.failure(error))
                }
            case .userCancelled:
                print("Користувач скасував покупку")
                
            default:
                break
            }
        } catch {
            print("Помилка покупки: \(error)")
            completion(.failure(error))
        }
    }
    
    
    func getPrice(productID: String, products: [Product]) -> String {
        for product in products {
            if product.id == productID {
                return "\(product.price)"
            }
        }
        return "-"
    }
    
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            print("Покупки відновлено")
            UserDefaults.standard.set(true, forKey: "isPremiumUser")
        } catch {
            print("Помилка відновлення покупок: \(error)")
        }
    }
    
    
    func listenForTransactionUpdates() async {
        for await verification in Transaction.updates {
            switch verification {
            case .verified(let transaction):
                print("Verified transaction: \(transaction.productID)")
                await transaction.finish()
            case .unverified(_, let error):
                print("Unverified transaction: \(error)")
            }
        }
    }
    
    
    
    
    func checkSubscriptionStatus(for productID: String) async -> Bool {
        do {
            // Завантажити продукт
            let products = try await Product.products(for: [productID])
            guard let product = products.first, let subscription = product.subscription else {
                print("Продукт або підписка не знайдені")
                return false
            }
            
            // Отримати статус підписки
            let status = try await subscription.status
            for statusItem in status {
                switch statusItem.state {
                case .subscribed:
                    print("У користувача є активна підписка")
                    return true
                case .expired:
                    print("Підписка закінчилася")
                    return false
                case .inGracePeriod:
                    print("Підписка в періоді пільгового поновлення")
                    return true
                case .revoked:
                    print("Підписка була скасована")
                    return false
                default:
                    print("Інший статус підписки: \(statusItem.state)")
                    return false
                    
                }
            }
        } catch {
            print("Помилка перевірки статусу підписки: \(error)")
            return false
            
        }
        return false
    }
}
