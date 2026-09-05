//
//  RestorationsView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 13.11.2024.
//

import SwiftUI
import PhotosUI

struct EditingView: View {
    
    @EnvironmentObject var localFilesManager: LocalFilesManager
    @EnvironmentObject var editingViewModObserver: EditingViewModObserver
    @Environment(\.presentationMode) var presentationMode
    
    @State var editingViewMod: EditingViewMode = .restorations
    @State var navigationTitle = ""
    @State var notifyMe = false
    @State var presentErrorAlert = false
    @State var presentPaywall = false
    @State private var isLoading = false
    @State var showProcessingView = false
    @State var showResultView = false
    @State var resultEditing = ResultImageModel(inputURL: "", outputURL: "", isGenerated: false)
    
    let editingManager = EditingManager()
    
    //Base
    private var apiKey = "b8642b2f16ea475c92a51a603d511561"
    @State var selectedImageData = Data()
    
    //Restorations
    @State var decompress = ""
    @State var upscale = ""
    
    //Resizing
    @State var width = ""
    @State var height = ""
    @State var fit = ""
    @State var resizingType: ResizingType = .empty
    
    //Padding
    @State var backgroundRemove = true
    @State var top = "0"
    @State var bottom = "0"
    @State var left = "0"
    @State var right = "0"
    
    //ColorAdjustments
    @State var hdr = 0
    @State var exposure = 0
    @State var saturation = 0
    @State var contrast = 0
    @State var sharpness = 0
    
    //Background
    @State var hexColor = ""
    @State var bgColor = Color.white
    @State var transparent = true
    
    
    var body: some View {
        
        NavigationStack {
            
            VStack {
                
                ZStack {
                    
                    LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                                   startPoint: .bottomLeading,
                                   endPoint: .topTrailing)
                    .ignoresSafeArea()
                    .navigationTitle("\(navigationTitle)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image("close 1")
                                    .zIndex(0)
                                    .padding()
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    
                    
                    
                    ScrollView {
                        
                        ImagePickerView(selectedImageData: $selectedImageData)
                        
                        VStack {
                            switch editingViewModObserver.editingViewMod {
                            case .restorations:
                                RestorationsUI(selectedUpscaleString: $upscale,
                                               decompress: $decompress)
                                
                            case .resizing:
                                ResizingUI(imageWidth: $width,
                                           imageHeight: $height,
                                           fit: $fit,
                                           resizingType: $resizingType)
                                
                            case .padding:
                                PaddingUI(top: $top,
                                          left: $left,
                                          right: $right,
                                          bottom: $bottom,
                                          removeBackground: $backgroundRemove)
                                
                            case .colorAdjustments:
                                ColorAdjustmentsUI(hdr: $hdr,
                                                   exposure: $exposure,
                                                   saturation: $saturation,
                                                   contrast: $contrast,
                                                   sharpness: $sharpness)
                            case .background:
                                BackgroundEditingUI(bgColor: $bgColor, transparent: $transparent)
                            }
                            
                        }.padding(.bottom, 90)
                            .padding(.horizontal, 5)
                        
                    }.scrollIndicators(.hidden)
                    
                    
                    VStack {
                        
                        Spacer()
                        
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            isLoading = true
                            
                            switch  UserDefaults.standard.bool(forKey: "isPremiumUser") {
                            case true:
                                showProcessingView = true
                                isLoading = false
                                if let image = UIImage(data: selectedImageData) {
                                    editingManager.uploadImage(apiKey: apiKey, image: image) { inputURL in
                                        switch editingViewModObserver.editingViewMod {
                                        case .restorations:
                                            guard let image = UIImage(data: selectedImageData) else { return }
                                            editingManager.restorations(apiKey: apiKey,
                                                                        decompress: decompress,
                                                                        upscale: upscale,
                                                                        imageURL: inputURL,
                                                                        image: image) { outputURL in
                                                isLoading = false
                                                switch outputURL {
                                                case .success(let success):
                                                    
                                                    if showProcessingView == true {
                                                        resultEditing.inputURL = inputURL
                                                        resultEditing.outputURL = success
                                                        DispatchQueue.main.async {
                                                            resultEditing.isGenerated = false
                                                            showProcessingView = false
                                                            showResultView = true
                                                        }
                                                    }
                                                    
                                                    let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                   outputURL: success,
                                                                                                   isGenerated: false)
                                                    showProcessingView = false
                                                    localFilesManager.addItem(restorationsResultImage)
                                                case .failure(_):
                                                    showProcessingView = false
                                                    presentErrorAlert = true
                                                }
                                            }
                                            
                                            
                                        case .resizing:
                                            switch resizingType {
                                            case .empty:
                                                editingManager.resizingEmpty(apiKey: apiKey,
                                                                             imageURL: inputURL,
                                                                             width: Int(width) ?? 0,
                                                                             fit: fit) { outputURL in
                                                    
                                                    isLoading = false
                                                    switch outputURL {
                                                    case .success(let success):
                                                        
                                                        if showProcessingView == true {
                                                            resultEditing.inputURL = inputURL
                                                            resultEditing.outputURL = success
                                                            DispatchQueue.main.async {
                                                                resultEditing.isGenerated = false
                                                                showProcessingView = false
                                                                showResultView = true
                                                            }
                                                        }
                                                        
                                                        
                                                        let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                       outputURL: success,
                                                                                                       isGenerated: false)
                                                        showProcessingView = false
                                                        localFilesManager.addItem(restorationsResultImage)
                                                    case .failure(_):
                                                        showProcessingView = false
                                                        presentErrorAlert = true
                                                    }
                                                }
                                                
                                            case .auto:
                                                editingManager.resizingAuto(apiKey: apiKey,
                                                                            imageURL: inputURL,
                                                                            height: Int(height) ?? 0,
                                                                            fit: fit) { outputURL in
                                                    isLoading = false
                                                    switch outputURL {
                                                    case .success(let success):
                                                        
                                                        if showProcessingView == true {
                                                            resultEditing.inputURL = inputURL
                                                            resultEditing.outputURL = success
                                                            DispatchQueue.main.async {
                                                                resultEditing.isGenerated = false
                                                                showProcessingView = false
                                                                showResultView = true
                                                            }
                                                        }
                                                        
                                                        
                                                        let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                       outputURL: success,
                                                                                                       isGenerated: false)
                                                        showProcessingView = false
                                                        localFilesManager.addItem(restorationsResultImage)
                                                    case .failure(_):
                                                        showProcessingView = false
                                                        presentErrorAlert = true
                                                    }
                                                }
                                                
                                            case .pixels:
                                                editingManager.resizingInt(apiKey: apiKey,
                                                                           imageURL: inputURL,
                                                                           width: Int(width) ?? 0,
                                                                           height: Int(height) ?? 0,
                                                                           fit: fit) { outputURL in
                                                    
                                                    isLoading = false
                                                    switch outputURL {
                                                    case .success(let success):
                                                        
                                                        if showProcessingView == true {
                                                            resultEditing.inputURL = inputURL
                                                            resultEditing.outputURL = success
                                                            DispatchQueue.main.async {
                                                                resultEditing.isGenerated = false
                                                                showProcessingView = false
                                                                showResultView = true
                                                            }
                                                        }
                                                        
                                                        
                                                        let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                       outputURL: success,
                                                                                                       isGenerated: false)
                                                        showProcessingView = false
                                                        localFilesManager.addItem(restorationsResultImage)
                                                    case .failure(_):
                                                        showProcessingView = false
                                                        presentErrorAlert = true
                                                    }
                                                }
                                                
                                            case .percentage:
                                                editingManager.resizing(apiKey: apiKey,
                                                                        imageURL: inputURL,
                                                                        width: "\(width)%",
                                                                        height: "\(height)%",
                                                                        fit: fit) { outputURL in
                                                    isLoading = false
                                                    switch outputURL {
                                                    case .success(let success):
                                                        
                                                        if showProcessingView == true {
                                                            resultEditing.inputURL = inputURL
                                                            resultEditing.outputURL = success
                                                            DispatchQueue.main.async {
                                                                resultEditing.isGenerated = false
                                                                showProcessingView = false
                                                                showResultView = true
                                                            }
                                                        }
                                                        
                                                        let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                       outputURL: success,
                                                                                                       isGenerated: false)
                                                        showProcessingView = false
                                                        localFilesManager.addItem(restorationsResultImage)
                                                    case .failure(_):
                                                        showProcessingView = false
                                                        presentErrorAlert = true
                                                    }
                                                }
                                            }
                                            
                                        case .padding:
                                            editingManager.padding(apiKey: apiKey,
                                                                   imageURL: inputURL,
                                                                   backgroundRemove: backgroundRemove,
                                                                   top: top,
                                                                   bottom: bottom,
                                                                   left: left,
                                                                   right: right) { outputURL in
                                                isLoading = false
                                                switch outputURL {
                                                case .success(let success):
                                                    
                                                    if showProcessingView == true {
                                                        resultEditing.inputURL = inputURL
                                                        resultEditing.outputURL = success
                                                        DispatchQueue.main.async {
                                                            resultEditing.isGenerated = false
                                                            showProcessingView = false
                                                            showResultView = true
                                                        }
                                                    }
                                                    
                                                    let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                   outputURL: success,
                                                                                                   isGenerated: false)
                                                    showProcessingView = false
                                                    localFilesManager.addItem(restorationsResultImage)
                                                case .failure(_):
                                                    showProcessingView = false
                                                    presentErrorAlert = true
                                                }
                                            }
                                            
                                        case .colorAdjustments:
                                            editingManager.colorAdjustments(apiKey: apiKey,
                                                                            imageURL: inputURL,
                                                                            hdr: hdr,
                                                                            exposure: exposure,
                                                                            saturation: saturation,
                                                                            contrast: contrast,
                                                                            sharpness: sharpness) { outputURL in
                                                isLoading = false
                                                switch outputURL {
                                                case .success(let success):
                                                    
                                                    if showProcessingView == true {
                                                        resultEditing.inputURL = inputURL
                                                        resultEditing.outputURL = success
                                                        DispatchQueue.main.async {
                                                            resultEditing.isGenerated = false
                                                            showProcessingView = false
                                                            showResultView = true
                                                        }
                                                    }
                                                    
                                                    let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                   outputURL: success,
                                                                                                   isGenerated: false)
                                                    showProcessingView = false
                                                    localFilesManager.addItem(restorationsResultImage)
                                                case .failure(_):
                                                    showProcessingView = false
                                                    presentErrorAlert = true
                                                }
                                            }
                                            
                                        case .background:
                                            if transparent {
                                                hexColor = "transparent"
                                            } else {
                                                if let color = bgColor.toHexString() {
                                                    hexColor = color
                                                }
                                            }
                                            
                                            editingManager.backgroundEditing(apiKey: apiKey,
                                                                             imageURL: inputURL,
                                                                             color: hexColor) { outputURL in
                                                isLoading = false
                                                switch outputURL {
                                                case .success(let success):
                                                    
                                                    if showProcessingView == true {
                                                        resultEditing.inputURL = inputURL
                                                        resultEditing.outputURL = success
                                                        DispatchQueue.main.async {
                                                            resultEditing.isGenerated = false
                                                            showProcessingView = false
                                                            showResultView = true
                                                        }
                                                    }
                                                    
                                                    let restorationsResultImage = ResultImageModel(inputURL: inputURL,
                                                                                                   outputURL: success,
                                                                                                   isGenerated: false)
                                                    showProcessingView = false
                                                    localFilesManager.addItem(restorationsResultImage)
                                                case .failure(_):
                                                    showProcessingView = false
                                                    presentErrorAlert = true
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    showProcessingView = false
                                    presentErrorAlert = true
                                    isLoading = false
                                    print("Не вдалося знайти зображення.")
                                }
                                
                            case false:
                                presentPaywall = true
                                isLoading = false
                            }
                            
                            
                        }label: {
                            Text("Generate")
                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .padding()
                        }.background(
                            selectedImageData.isEmpty ? LinearGradient(gradient: Gradient(colors: [.backgroundGray]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        
                        .padding(.top, 10)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .disabled(selectedImageData.isEmpty)
                        
                    }
                    
                    if presentErrorAlert {
                        ZStack {
                            BlurView(style: .systemUltraThinMaterialDark)
                                .ignoresSafeArea()
                            ErrorAlert(presentAlert: $presentErrorAlert, textAlert: "You received an error, try other settings for this image or contact support")
                        }
                        
                    }
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Text("")
                    }
                }.hideKeyboardOnTap()
            }
            .fullScreenCover(isPresented: $showProcessingView) {
                ProcessingView(notifyMe: $notifyMe)
            }
            .fullScreenCover(isPresented: $showResultView) {
                ResultEditImageView(resultImage: resultEditing)
            }
            .fullScreenCover(isPresented: $presentPaywall) {
                Paywall()
            }
        }.onAppear {
            switch editingViewModObserver.editingViewMod {
            case .restorations:
                navigationTitle = "Restorations"
            case .resizing:
                navigationTitle = "Resizing"
            case .padding:
                navigationTitle = "Padding"
            case .colorAdjustments:
                navigationTitle = "Color adjustments"
            case .background:
                navigationTitle = "Background"
            }
        }
    }
}


#Preview {
    EditingView()
        .environmentObject(LocalFilesManager())
        .environmentObject(EditingViewModObserver())
}



extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
