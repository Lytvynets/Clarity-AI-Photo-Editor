//
//  CustomNotification.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 09.12.2024.
//

import SwiftUI

struct CustomNotification: View {
    
    var body: some View {
        VStack {
            
            HStack {
                
                Text("Generation complete!")
                    .font(.custom("Lato-Bold", size: 18))
                    .padding(.bottom, 5)
                    .foregroundStyle(.purple)
                
                Spacer()
                
            }.padding(.horizontal, 20)
                .padding(.top)
            
            HStack {
                
                Text("The generation was completed successfully, you can view the result in the history")
                    .font(.custom("Lato-Light", size: 15))
                
                Spacer()
                
            }.padding(.horizontal, 20)
                .padding(.bottom)
        }.background(.backgroundAlert)
        .cornerRadius(27)
    }
}

#Preview {
    CustomNotification()
}
