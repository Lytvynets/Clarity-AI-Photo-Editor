//
//  DeleteAlert.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 09.12.2024.
//

import SwiftUI

struct DeleteAlert: View {
    
    @Binding var presentDeleteAlert: Bool
    @Binding var wasDeleted: Bool
    @Binding var resultImage: ResultImageModel
    @EnvironmentObject var localFilesManager: LocalFilesManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            
            Image("bin")
                .resizable()
                .frame(width: 70, height: 70)
                .padding()
                .padding(.top)
            
            Text("Do you really want to delete this image?")
                .font(.custom("Lato-Bold", size: 15))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 25)
                .padding(.bottom)
            
            Divider()
                .frame(width: 300)
            
            HStack {
                
                Button {
                    print("Cancel")
                    presentDeleteAlert = false
                }label: {
                    Text("Cancel")
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .font(.custom("Lato-Bold", size: 17))
                        .foregroundStyle(.red)
                }.padding()
                    .padding(.horizontal)
                
                Button {
                    localFilesManager.deleteItem(resultImage) { deleted in
                        if deleted == true {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    presentDeleteAlert = false
                    wasDeleted = true
                }label: {
                    Text("Yes")
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .font(.custom("Lato-Bold", size: 17))
                        .foregroundStyle(.white)
                }.padding()
                    .padding(.horizontal)
            }
        }.background(.backgroundAlert)
            .cornerRadius(30)
    }
}

#Preview {
    //    @State var presentDeleteAlert: Bool = true
    //    @State var wasDeleted: Bool = true
    //    @State var resultImage = ResultImageModel(from: "" as! Decoder)
    //
    //    DeleteAlert(presentDeleteAlert: $presentDeleteAlert, wasDeleted: $wasDeleted, resultImage: $resultImage)
    //        .environmentObject(LocalFilesManager())
}
