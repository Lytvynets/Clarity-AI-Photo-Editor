//
//  ShareSheet.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 12.12.2024.
//

import Foundation
import UIKit
import SwiftUI


struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
