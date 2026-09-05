//
//  RestorationsUI.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 15.11.2024.
//

import SwiftUI

enum SelectedUpscale {
    case photo
    case faces
    case digitalArt
    case smartResize
    case smartEnhance
}


struct RestorationsUI: View {
    
    @State var selectedUpscale: SelectedUpscale = .photo
    @Binding var selectedUpscaleString: String
    @Binding var decompress: String
    
    var body: some View {
        VStack {
            
            CustomSegmentedControl(decompress: $decompress)
                .padding()
            
            HStack {
                
                Text("Upscale")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
                
            }.padding(.top)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        selectedUpscale = .photo
                        selectedUpscaleString = "photo"
                    }label: {
                        Text("Photo")
                            .font(.custom("Lato-Italic", size: 15))
                            .foregroundStyle(selectedUpscale == .photo ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(selectedUpscale == .photo ? .white : .clear)
                        
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
                        selectedUpscale = .faces
                        selectedUpscaleString = "faces"
                    }label: {
                        Text("Faces")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(selectedUpscale == .faces ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(selectedUpscale == .faces ? .white : .clear)
                        
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
                        selectedUpscale = .digitalArt
                        selectedUpscaleString = "digital_art"
                    }label: {
                        Text("Digital art")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(selectedUpscale == .digitalArt ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(selectedUpscale == .digitalArt ? .white : .clear)
                        
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
                        selectedUpscale = .smartResize
                        selectedUpscaleString = "smart_resize"
                    }label: {
                        Text("Smart resize")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(selectedUpscale == .smartResize ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(selectedUpscale == .smartResize ? .white : .clear)
                        
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
                        selectedUpscale = .smartEnhance
                        selectedUpscaleString = "smart_enhance"
                    }label: {
                        Text("Smart enhance")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(selectedUpscale == .smartEnhance ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(selectedUpscale == .smartEnhance ? .white : .clear)
                            .background(
                                BlurView(style: .systemUltraThinMaterialDark)
                                    .opacity(0.7)
                                    .blur(radius: 1)
                            )
                        
                            .clipShape(.capsule)
                    }
                }
            }.padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
}

#Preview {
 //   RestorationsUI()
}
