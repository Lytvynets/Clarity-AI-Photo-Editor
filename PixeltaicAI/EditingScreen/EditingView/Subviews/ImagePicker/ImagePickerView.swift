//
//  ImagePickerView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 30.11.2024.
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = UIImage(named: "pictures-3")
    @Binding var selectedImageData: Data
    
    var body: some View {
        
        VStack {
            
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(20)
                    .padding()
            } else {
                Text("Select an image")
                    .foregroundColor(.gray)
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose a photo")
                    .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                    .padding()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .background(
                        
                        BlurView(style: .systemUltraThinMaterialDark)
                            .opacity(0.7)
                            .blur(radius: 1)
                        
                    )
                    .clipShape(.capsule)
                    .padding(.horizontal)
                
            }
            .onChange(of: selectedItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       
                        let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        selectedImageData = data
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    //   ImagePickerView()
}
