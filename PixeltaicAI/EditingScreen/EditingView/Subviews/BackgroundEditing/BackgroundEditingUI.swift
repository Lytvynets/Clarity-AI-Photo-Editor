//
//  BackgroundEditingUI.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 16.11.2024.
//

import SwiftUI

struct BackgroundEditingUI: View {
    
    @Binding var bgColor: Color
    @Binding var transparent: Bool
    
    var body: some View {
        
        VStack {
            
            if #available(iOS 17.0, *) {
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack {
                        
                        Button {
                            transparent = true
                        }label: {
                            Text("Transparent")
                                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                .foregroundStyle(transparent == true ? .black : .white)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width / 2.4)
                                .background(transparent == true ? .white : .clear)
                                .background(
                                    BlurView(style: .systemUltraThinMaterialDark)
                                        .opacity(0.7)
                                        .blur(radius: 1)
                                )
                                .clipShape(.capsule)
                        }
                        
                        Button {
                            transparent = false
                        }label: {
                            Text("Pick color")
                                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                .foregroundStyle(transparent == false ? .black : .white)
                                .padding()
                                .frame(width: UIScreen.main.bounds.width / 2.4)
                                .background(transparent == false ? .white : .clear)
                                .background(
                                    BlurView(style: .systemUltraThinMaterialDark)
                                        .opacity(0.7)
                                        .blur(radius: 1)
                                )
                                .clipShape(.capsule)
                        }
                    }
                }.defaultScrollAnchor(.center)
                    .scrollIndicators(.hidden)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    HStack {
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            transparent = true
                        }label: {
                            Text("Transparent")
                                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                .foregroundStyle(transparent == true ? .black : .white)
                                .padding()
                                .padding(.horizontal, 15)
                                .background(transparent == true ? .white : .clear)
                                .background(
                                    BlurView(style: .systemUltraThinMaterialDark)
                                        .opacity(0.7)
                                        .blur(radius: 1)
                                )
                                .clipShape(.capsule)
                        }
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            transparent = false
                        }label: {
                            Text("Pick color")
                                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                .foregroundStyle(transparent == false ? .black : .white)
                                .padding()
                                .padding(.horizontal, 15)
                                .background(transparent == false ? .white : .clear)
                                .background(
                                    BlurView(style: .systemUltraThinMaterialDark)
                                        .opacity(0.7)
                                        .blur(radius: 1)
                                )
                                .clipShape(.capsule)
                        }
                    }.padding(.horizontal)
                }.scrollIndicators(.hidden)
            }
            
            if !transparent {
                ColorPicker("Background color", selection: $bgColor, supportsOpacity: false)
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding()
                    .padding(.horizontal)
            }
        }
    }
}


#Preview {
    //   BackgroundEditingUI()
}
