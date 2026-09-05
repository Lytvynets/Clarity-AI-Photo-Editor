//
//  PaddingUI.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 16.11.2024.
//

import SwiftUI

struct PaddingUI: View {
    
    @Binding var top: String
    @Binding var left: String
    @Binding var right: String
    @Binding var bottom: String
    @Binding var removeBackground: Bool
    
    var body: some View {
        
        VStack {
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                removeBackground.toggle()
            }label: {
                Text("Remove background")
                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                    .foregroundStyle(removeBackground ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(removeBackground ? .white : .clear)
                    .background(
                        BlurView(style: .systemUltraThinMaterialDark)
                            .opacity(0.7)
                            .blur(radius: 1)
                    )
                    .clipShape(.capsule)
            }.padding(.bottom)
                .padding(.horizontal, 30)
            
            
            TextField(
                "Top", text: $top
                
            ).frame(width: 140, height: 35)
                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                .multilineTextAlignment(.center)
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .opacity(0.5)
                        .blur(radius: 1)
                        .clipShape(.capsule)
                    
                )
            
            
            HStack {
                TextField(
                    "Left", text: $left
                    
                ).frame(width: 140, height: 35)
                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                    .multilineTextAlignment(.center)
                    .background(
                        BlurView(style: .systemUltraThinMaterialDark)
                            .opacity(0.5)
                            .blur(radius: 1)
                            .clipShape(.capsule)
                        
                    ).padding()
                
                Spacer()
                
                TextField(
                    "Right", text: $right
                    
                ).frame(width: 140, height: 35)
                    .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                    .multilineTextAlignment(.center)
                    .background(
                        BlurView(style: .systemUltraThinMaterialDark)
                            .opacity(0.5)
                            .blur(radius: 1)
                            .clipShape(.capsule)
                        
                    ).padding()
            }
            
            
            TextField(
                "Bottom", text: $bottom
                
            ).frame(width: 140, height: 35)
                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                .multilineTextAlignment(.center)
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .opacity(0.5)
                        .blur(radius: 1)
                        .clipShape(.capsule)
                    
                )
        }
    }
}


#Preview {
//    @State var top: String = "0"
//    @State var left: String = "0"
//    @State var right: String = "0"
//    @State var bottom: String = "0"
//    @State var removeBackground: Bool = false
//    PaddingUI(top: $top,
//              left: $left,
//              right: $right,
//              bottom: $bottom,
//              removeBackground: $removeBackground)
}
