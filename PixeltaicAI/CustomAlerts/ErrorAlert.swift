//
//  ErrorAlert.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 09.12.2024.
//

import SwiftUI

struct ErrorAlert: View {
    
    @Binding var presentAlert: Bool
    @State var textAlert = ""
    
    var body: some View {
        
        VStack {
            
            Image("warning")
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
            
            Text(textAlert)
                .font(.custom("Lato-Bold", size: 15))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 25)
                .padding(.bottom)
            
            Divider()
                .frame(width: UIScreen.main.bounds.width / 1.2)
            
            Button {
                print("ok")
                presentAlert = false
            }label: {
                Text("Ok")
                    .font(.custom("Lato-Bold", size: 17))
                    .foregroundStyle(.white)
                    .padding(.horizontal)
            }.padding()
            
        }.background(.backgroundAlert)
            .cornerRadius(30)
    }
}

#Preview {
    @State var presentAlert: Bool = true
    ErrorAlert(presentAlert: $presentAlert, textAlert: "Error")
}
