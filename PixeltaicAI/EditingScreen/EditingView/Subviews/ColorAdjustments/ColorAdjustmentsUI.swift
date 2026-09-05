//
//  ColorAdjustmentsUI.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 16.11.2024.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ColorAdjustmentsUI: View {
    
    @State var hdrValue: Float = 0
    @State var exposureValue: Float = 0
    @State var saturationValue: Float = 0
    @State var contrastValue: Float = 0
    @State var sharpnessValue: Float = 0
    @Binding var hdr: Int
    @Binding var exposure: Int
    @Binding var saturation: Int
    @Binding var contrast: Int
    @Binding var sharpness: Int
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                Text("HDR")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            Slider(value: $hdrValue, in: 0...100) {
            }onEditingChanged: { change in
                hdr = Int(hdrValue)
            }.padding(.horizontal)
                .tint(.buttonGradient2)
            
            
            HStack {
                
                Text("Exposure")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            Slider(value: $exposureValue, in: -100...100) {
            }onEditingChanged: { change in
                exposure = Int(exposureValue)
            }.padding(.horizontal)
                .tint(.buttonGradient2)
            
            
            HStack {
                
                Text("Saturation")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            Slider(value: $saturationValue, in: -100...100) {
            }onEditingChanged: { change in
                saturation = Int(saturationValue)
            }.padding(.horizontal)
                .tint(.buttonGradient2)
            
            
            HStack {
                
                Text("Contrast")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            Slider(value: $contrastValue, in: -100...100) {
            }onEditingChanged: { change in
                contrast = Int(contrastValue)
            }.padding(.horizontal)
                .tint(.buttonGradient2)
            
            HStack {
                
                Text("Sharpness")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            Slider(value: $sharpnessValue, in: 0...100) {
            }onEditingChanged: { change in
                sharpness = Int(sharpnessValue)
            }.padding(.horizontal)
                .tint(.buttonGradient2)
        }.padding(.horizontal, 5)
    }
}

#Preview {
    //ColorAdjustmentsUI()
}
