//
//  CustomSegmentedControl.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 20.11.2024.
//

import SwiftUI

struct CustomSegmentedControl: View {
    
    @State var selectedSegment = 0
    @Binding var decompress: String
    
    var body: some View {
        HStack {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                selectedSegment = 0
                decompress = "moderate"
                
            }label: {
                Text("Medium")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                    .padding(.horizontal)
                    .foregroundStyle(selectedSegment == 0 ? .black : .white)
            }.padding()
                .background(selectedSegment == 0 ? .white : .clear)
                .clipShape(.capsule)
            
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                selectedSegment = 1
                decompress = "strong"
            }label: {
                Text("Strong")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                    .padding(.horizontal)
                    .foregroundStyle(selectedSegment == 1 ? .black : .white)
            }.padding()
                .background(selectedSegment == 1 ? .white : .clear)
                .clipShape(.capsule)
            
            
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                selectedSegment = 2
                decompress = "auto"
            }label: {
                Text("Auto")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.medium))
                    .padding(.horizontal)
                    .foregroundStyle(selectedSegment == 2 ? .black : .white)
            }.padding()
                .background(selectedSegment == 2 ? .white : .clear)
                .clipShape(.capsule)
        }.background(
            BlurView(style: .systemUltraThinMaterialDark)
                .opacity(0.5)
                .blur(radius: 1)
        ).clipShape(.capsule)
    }
}

#Preview {
 //   CustomSegmentedControl(, decompress: <#Binding<String>#>)
}
