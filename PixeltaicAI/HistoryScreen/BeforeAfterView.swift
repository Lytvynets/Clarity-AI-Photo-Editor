//
//  BeforeAfterView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 23.11.2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct BeforeAfterView: View {
    
    @State private var sliderPosition: CGFloat = 0.0
    var beforeImage: String
    var afterImage: String
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ZStack {
                
                WebImage(url: URL(string: beforeImage))
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(20)
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                
                WebImage(url: URL(string: afterImage))
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .cornerRadius(20)
                    .aspectRatio(contentMode: .fit)
                
                    .mask(
                        HStack {
                            Spacer()
                                .frame(width: geometry.size.width * sliderPosition + geometry.size.width / 2)
                            Rectangle()
                        }
                    )
                
                Rectangle()
                    .frame(width: 2, height: geometry.size.height)
                    .foregroundColor(.white)
                    .offset(x: geometry.size.width * sliderPosition)
                
                Rectangle()
                    .cornerRadius(10)
                    .frame(width: 35, height: 35)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .offset(x: geometry.size.width * sliderPosition, y: geometry.size.width / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = value.location.x / geometry.size.width
                                sliderPosition = max(-0.5, min(newPosition, 0.5))
                            }
                    )
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}


#Preview {
    BeforeAfterView(beforeImage: "ai-generated-g43d2b29be_1920", afterImage: "generation")
}
