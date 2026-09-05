//
//  AdaptiveFontSize.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 23.11.2024.
//

import Foundation
import SwiftUI


struct AdaptiveFontSize {
    
    static var shared = AdaptiveFontSize()
    
    let medium = UIScreen.main.bounds.height * 0.018
    let large = UIScreen.main.bounds.height * 0.022
    let small = UIScreen.main.bounds.height * 0.014
    let onboardingTitle = UIScreen.main.bounds.height * 0.032
    let onboardingSubtitle = UIScreen.main.bounds.height * 0.021
    
    let paywallTitle = UIScreen.main.bounds.height * 0.018
    let paywallSubtitle = UIScreen.main.bounds.height * 0.021
    let paywallPrice = UIScreen.main.bounds.height * 0.016
    let paywallPrice2 = UIScreen.main.bounds.height * 0.015
}
