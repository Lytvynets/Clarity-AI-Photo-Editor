//
//  ShareSheetURL.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 12.12.2024.
//

import Foundation
import SwiftUI

struct ShareSheetURL: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
