//
//  BlurView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 23.11.2024.
//

import Foundation
import SwiftUI


struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
