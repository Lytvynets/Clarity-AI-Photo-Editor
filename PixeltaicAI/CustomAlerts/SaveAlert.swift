//
//  SaveAlert.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 09.12.2024.
//

import SwiftUI

struct SaveAlert: View {
    
    @Binding var presentSaveAlert: Bool
    
    var body: some View {
        
        VStack {
            
            Image("healthy")
                .resizable()
                .frame(width: 75, height: 75)
                .padding()
                .padding(.top)
            
            Text("Saved")
                .font(.custom("Lato-Bold", size: 23))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
            
            Divider()
                .frame(width: 250)
            
            Button {
                print("ok")
                presentSaveAlert = false
            }label: {
                Text("Ok")
                    .font(.custom("Lato-Bold", size: 18))
                    .foregroundStyle(.white)
            }.padding()
            
        }.background(.backgroundAlert)
        .cornerRadius(30)
    }
}

#Preview {
    @State var presentSaveAlert: Bool = true
    SaveAlert(presentSaveAlert: $presentSaveAlert)
}
