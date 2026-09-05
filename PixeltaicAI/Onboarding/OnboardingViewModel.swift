//
//  OnboardingViewModel.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 13.07.2025.
//

import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    
    @Published var showOnboarding = false
    
    
    var onboardingItems: [OnboardingItemModel] = [OnboardingItemModel(title: "Restore Lost Details",
                                                                      subTitle: "Bring back the original clarity and sharpness of \nyour photos using our powerful AI tools. Perfect \nfor improving old or blurry images effortlessly.",
                                                                      imageName: "OnbIMG1"),
                                                  OnboardingItemModel(title: "Color Adjustments",
                                                                      subTitle: "Fine-tune the color settings of your images, \nincluding brightness, contrast, saturation, and \nmore, to achieve the perfect look.",
                                                                      imageName: "OnbIMG2"),
                                                  OnboardingItemModel(title: "Background Removal",
                                                                      subTitle: "Quickly and precisely erase image backgrounds \nwith a single touch. Ideal for portraits, product \nphotos, and creative projects of all kinds.",
                                                                      imageName: "Group 1000003572"),
                                                  OnboardingItemModel(title: "Generate AI Images",
                                                                      subTitle: "Generate stunning AI-powered images — from \nrealistic portraits to fantastical scenes. Just \ndescribe your idea and let the magic happen.",
                                                                      imageName: "Group 2325873253")]
    
    
    
    
}
