//
//  AppDelegate.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 02.12.2024.
//

import Foundation
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserDefaults.standard.set(false, forKey: "isPremiumUser")
        return true
    }
    
}
