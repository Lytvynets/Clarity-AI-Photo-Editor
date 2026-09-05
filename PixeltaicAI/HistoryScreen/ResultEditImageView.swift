//
//  ResultView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 18.11.2024.
//

import SwiftUI
import SDWebImageSwiftUI
import Photos

enum ResultViewState {
    case editingResult
    case generatingResult
    case generatingMoreImagesResult
}


struct ResultEditImageView: View {
    
    @State private var isLoading = false
    @State private var presentErrorAlert = false
    @State private var presentDeleteAlert = false
    @State private var wasDeleted = false
    @State private var presentSaveAlert = false
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?
    @State private var stateView: ResultViewState = .editingResult
    @EnvironmentObject var localFilesManager: LocalFilesManager
    
    @Environment(\.dismiss) var dismiss
    @State var resultImage: ResultImageModel
    @State private var isShareSheetPresented = false
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing)
                .ignoresSafeArea()
                .navigationTitle("Result")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    Button {
                        dismiss()
                    }label: {
                        Image("close 1")
                    }
                }
                
                ScrollView {
                    
                    VStack {
                        if resultImage.isGenerated {
                            WebImage(url: URL(string: resultImage.outputURL))
                                .resizable()
                                .frame(width: UIScreen.main.bounds.width / 1.1 , height: UIScreen.main.bounds.height / 2.5)
                                .cornerRadius(20)
                                .aspectRatio(contentMode: .fit)
                                .padding()
                            
                        }else{
                            BeforeAfterView(beforeImage: resultImage.inputURL,
                                            afterImage: resultImage.outputURL)
                            .frame(width: 299, height: 350)
                            .cornerRadius(20)
                            .padding()
                        }
                        
                        
                        HStack {
                            
                            Button {
                                print("Delete")
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                presentDeleteAlert = true
                                
                            }label: {
                                HStack {
                                    Image("fluent_delete-16-regular")
                                    
                                    Text("Delete")
                                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.large))
                                        .foregroundStyle(.customRed)
                                        .padding(.vertical, 5)
                                }
                              
                            }.padding()
                                .frame(width: UIScreen.main.bounds.width / 2.4)
                                .background(
                                    Color(.darkRed)
                                        .opacity(0.6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                            
                            
                            Button {
                                print("Share")
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                isShareSheetPresented = true
                            }label: {
                                HStack {
                                    Image("uil_share")
                                    
                                    Text("Share")
                                        .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.large))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 5)
                                }
                                
                             
                            }.padding()
                                .frame(width: UIScreen.main.bounds.width / 2.4)
                                    .background(
                                        Color(.darkBlue)
                                            .opacity(0.6)
                                    )

                                .clipShape(RoundedRectangle(cornerRadius: 25))
                            
                        } .sheet(isPresented: $isShareSheetPresented) {
                            ShareSheet(items: [resultImage.outputURL])
                        }
                        
                        Button {
                            print("Save to gallery")
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            isLoading = true
                            saveImageToGallery { result in
                                switch result {
                                case .success(_):
                                    presentSaveAlert = true
                                    isLoading = false
                                case .failure(_):
                                    isLoading = false
                                    presentErrorAlert = true
                                }
                            }
                        }label: {
                            Text("Save to gallery")
                                .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.large))
                                .foregroundStyle(.white)
                                .padding(.vertical, 5)
                        }.padding()
                            .frame(width: UIScreen.main.bounds.width / 1.15)
                            .background(
                                BlurView(style: .systemUltraThinMaterialDark)
                                    .opacity(0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                }
                
                
                if presentDeleteAlert {
                    ZStack {
                        BlurView(style: .systemUltraThinMaterialDark)
                            .ignoresSafeArea()
                        
                        DeleteAlert(presentDeleteAlert: $presentDeleteAlert, wasDeleted: $wasDeleted, resultImage: $resultImage)
                            .environmentObject(localFilesManager)
                    }
                }
                
                
                if presentSaveAlert {
                    ZStack {
                        BlurView(style: .systemUltraThinMaterialDark)
                            .ignoresSafeArea()
                        SaveAlert(presentSaveAlert: $presentSaveAlert)
                    }
                }
                
                
                if presentErrorAlert {
                    if let textAlert = errorMessage {
                        ZStack {
                            BlurView(style: .systemUltraThinMaterialDark)
                                .ignoresSafeArea()
                            ErrorAlert(presentAlert: $presentErrorAlert, textAlert: textAlert)
                        }
                        
                    }
                }
                
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    Text("")
                }
            }
        }
    }
    
    
    private func saveImageToGallery(completion: @escaping ((Result<String, Error>) -> Void)) {
        isSaving = true
        saveSuccess = false
        errorMessage = nil
        
        guard let imageURL = URL(string: resultImage.outputURL) else { return }
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isSaving = false
                }
                return
            }
            
            guard let data = data, let uiImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid image data"
                    self.isSaving = false
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.saveSuccess = true
                        completion(.success("saveSuccess"))
                    } else {
                        
                        self.errorMessage = error?.localizedDescription ?? "Save error"
                        guard let error = error else { return }
                        completion(.failure(error))
                    }
                    self.isSaving = false
                }
            }
        }.resume()
    }
}


#Preview {
    let image = ResultImageModel(inputURL: "", outputURL: "", isGenerated: false)
    ResultEditImageView( resultImage: image)
}

