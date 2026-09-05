//
//  SettingsCell.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 13.11.2024.
//

import SwiftUI

struct SettingsCell: View {
        
    let cellText: String
    
    var body: some View {
        
        HStack {
            Text(cellText)
                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                .padding(.leading, 20)
                .padding(.vertical, 20)
            
            Spacer()
            
        }.background(
            BlurView(style: .dark)
                .opacity(0.7)
                .blur(radius: 1.0)
        ).clipShape(.capsule)
        
    }
}

#Preview {
    SettingsCell(cellText: "Test text")
}
