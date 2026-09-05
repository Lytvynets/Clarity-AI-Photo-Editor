//
//  LaunchScreen.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 14.07.2025.
//

import SwiftUI

struct LaunchScreen: View {
    
    @State private var isVisibleLogo = false
    @State private var isVisibleText = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                           startPoint: .bottomLeading,
                           endPoint: .topTrailing)
            .ignoresSafeArea()
            
            
            VStack {
                Image("Logo v2-2")
                    .resizable()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .opacity(isVisibleLogo ? 1 : 0)
                    .animation(.easeIn(duration: 1), value: isVisibleLogo)
                    .onAppear {
                        isVisibleLogo = true
                    }
                
                Text("Pixeltaic AI")
                    .font(.custom("Lato-Bold", size: 24))
                     .font(.title)
                     .opacity(isVisibleText ? 1 : 0)
                     .foregroundStyle(.white)
                     .padding(.top, 10)
                     .animation(.easeIn(duration: 1), value: isVisibleText)
                     .onAppear {
                         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                             isVisibleText = true
                         }
                     }
            }
            .padding(.bottom, 70)
        }
    }
}

#Preview {
    LaunchScreen()
}
