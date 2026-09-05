//
//  ResizingUI.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 15.11.2024.
//

import SwiftUI

struct ResizingUI: View {
    
    @Binding var imageWidth: String
    @Binding var imageHeight: String
    @Binding var fit: String
    @Binding var resizingType: ResizingType
    @State var fitType: FitType = .crop
    
    var body: some View {
        VStack {
            
            HStack {
                
                Text("Resizing")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        resizingType = .empty
                    }label: {
                        Text("Empty")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(resizingType == .empty ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(resizingType == .empty ? .white : .clear)
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
                        resizingType = .auto
                    }label: {
                        Text("Auto")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(resizingType == .auto ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(resizingType == .auto ? .white : .clear)
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
                        resizingType = .pixels
                    }label: {
                        Text("Pixels")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(resizingType == .pixels ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(resizingType == .pixels ? .white : .clear)
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
                        resizingType = .percentage
                    }label: {
                        Text("Percentage")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(resizingType == .percentage ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(resizingType == .percentage ? .white : .clear)
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
            
            
            HStack {
                
                Text("Custom")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding(.top)
                    .padding(.horizontal, 26)
                    .foregroundStyle(.labelGray)
                
                Spacer()
            }
            
            HStack {
                
                switch resizingType {
                case .empty:
                    TextField(
                        "     Width", text: $imageWidth
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                    
                case .auto:
                    TextField(
                        "     Auto", text: $imageWidth
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                        .disabled(resizingType == .auto)
                    
                    TextField(
                        "    Height", text: $imageHeight
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                case .pixels:
                    TextField(
                        "     Width pixels", text: $imageWidth
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                    
                    TextField(
                        "    Height pixels", text: $imageHeight
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                case .percentage:
                    TextField(
                        "     Width %", text: $imageWidth
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                    
                    TextField(
                        "    Height %", text: $imageHeight
                        
                    ).frame(height: 45)
                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                        .background(
                            BlurView(style: .systemUltraThinMaterialDark)
                                .opacity(0.5)
                                .blur(radius: 1)
                                .clipShape(.capsule)
                            
                        ).padding(.horizontal)
                }
            }
            
            HStack {
                Text("Fit")
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
                        fitType = .crop
                        fit = "crop"
                    }label: {
                        Text("Crop")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(fitType == .crop ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(fitType == .crop ? .white : .clear)
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
                        fitType = .bounds
                        fit = "bounds"
                    }label: {
                        Text("Bounds")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(fitType == .bounds ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(fitType == .bounds ? .white : .clear)
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
                        fitType = .cover
                        fit = "cover"
                    }label: {
                        Text("Cover")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(fitType == .cover ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(fitType == .cover ? .white : .clear)
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
                        fitType = .canvas
                        fit = "canvas"
                    }label: {
                        Text("Canvas")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(fitType == .canvas ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(fitType == .canvas ? .white : .clear)
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
                        fitType = .outpaint
                        fit = "outpaint"
                    }label: {
                        Text("Outpaint")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(fitType == .outpaint ? .black : .white)
                            .padding()
                            .padding(.horizontal, 15)
                            .background(fitType == .outpaint ? .white : .clear)
                            .background(
                                BlurView(style: .systemUltraThinMaterialDark)
                                    .opacity(0.7)
                                    .blur(radius: 1)
                            )
                            .clipShape(.capsule)
                    }
                }
            }.padding(.horizontal)
        }
    }
}

#Preview {
    //  ResizingUI()
}
