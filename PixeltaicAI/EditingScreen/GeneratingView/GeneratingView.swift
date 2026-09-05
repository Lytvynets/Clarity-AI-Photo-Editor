//
//  GeneratingView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 18.11.2024.
//

import SwiftUI

struct GeneratingView: View {
    
    @State private var isLoading = false
    @State var presentPaywall = false
    @State var presentErrorAlert = false
    @State var notifyMe = false
    @State var showProcessingView = false
    @State var prompt = ""
    @State var guidanceScale: Float = 1
    @State var imagesCount = 1
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var localFilesManager: LocalFilesManager
    @EnvironmentObject var tabSelection: TabSelection
    @EnvironmentObject var notificationManager: NotificationManager
    let editingManager = EditingManager()
    private var apiKey = "b8642b2f16ea475c92a51a603d511561"
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing)
                .ignoresSafeArea()
                .navigationTitle("Generation image")
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
                    
                    VStack {
                        
                        HStack {
                            
                            Text("Prompt")
                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                                .foregroundStyle(.labelGray)
                            
                            Spacer()
                            
                        }.padding(.horizontal)
                            .padding(.top, 25)
                        
                        TextEditor(text: $prompt)
                            .frame(height: 142)
                            .padding(4)
                            .background(
                                BlurView(style: .systemUltraThinMaterialDark)
                                    .opacity(0.7)
                                    .blur(radius: 1)
                            )
                        
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                            .font(.custom("Outfit-Regular", fixedSize: AdaptiveFontSize.shared.medium))
                            .scrollDisabled(false)
                            .cornerRadius(15)
                            .padding()
                        
                        HStack {
                            
                            Text("Images count")
                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                                .padding(.top)
                                .foregroundStyle(.labelGray)
                            
                            Spacer()
                            
                        }.padding(.horizontal)
                        
                        
                        if #available(iOS 17.0, *) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                
                                HStack {
                                    
                                    Button {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        imagesCount = 1
                                    }label: {
                                        Text("1")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 1 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 1 ? .white : .clear)
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
                                        imagesCount = 2
                                    }label: {
                                        Text("2")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 2 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 2 ? .white : .clear)
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
                                        imagesCount = 3
                                    }label: {
                                        Text("3")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 3 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 3 ? .white : .clear)
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
                                        imagesCount = 4
                                    }label: {
                                        Text("4")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 4 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 4 ? .white : .clear)
                                            .background(
                                                BlurView(style: .systemUltraThinMaterialDark)
                                                    .opacity(0.7)
                                                    .blur(radius: 1)
                                            )
                                            .clipShape(.capsule)
                                    }
                                }
                            }.padding()
                                .defaultScrollAnchor(.center)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                
                                HStack {
                                    
                                    Button {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        imagesCount = 1
                                    }label: {
                                        Text("1")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 1 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 1 ? .white : .clear)
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
                                        imagesCount = 2
                                    }label: {
                                        Text("2")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 2 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 2 ? .white : .clear)
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
                                        imagesCount = 3
                                    }label: {
                                        Text("3")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 3 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 3 ? .white : .clear)
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
                                        imagesCount = 4
                                    }label: {
                                        Text("4")
                                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                                            .foregroundStyle(imagesCount == 4 ? .black : .white)
                                            .padding()
                                            .padding(.horizontal, 15)
                                            .background(imagesCount == 4 ? .white : .clear)
                                            .background(
                                                BlurView(style: .systemUltraThinMaterialDark)
                                                    .opacity(0.7)
                                                    .blur(radius: 1)
                                            )
                                            .clipShape(.capsule)
                                    }
                                }
                            }.padding()
                        }
                        
                        HStack {
                            
                            Text("Guidance scale")
                                .font(.custom("Lato-BoldItalic", size: AdaptiveFontSize.shared.large))
                                .padding(.top, 20)
                                .foregroundStyle(.labelGray)
                            
                            Spacer()
                            
                        }.padding(.horizontal)
                        
                        Slider(value: $guidanceScale, in: 1...49.99) {
                            
                        }onEditingChanged: { change in
                            print("guidanceScale: ")
                        }.padding(.horizontal)
                            .tint(.buttonGradient2)
                    }
                }.hideKeyboardOnTap()
                
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
                            editingManager.generatingImagesByPrompt(apiKey: apiKey,
                                                                    prompt: prompt,
                                                                    numberOfImages: imagesCount,
                                                                    guidanceScale: guidanceScale) { result in
                                isLoading = false
                                switch result {
                                case .success(let success):
                                    let generationResultImage = ResultImageModel(inputURL: success,
                                                                                 outputURL: success,
                                                                                 isGenerated: true)
                                    
                                    if showProcessingView {
                                        DispatchQueue.main.async {
                                            tabSelection.selectedTab = 1
                                            DispatchQueue.main.async {
                                                showProcessingView = false
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    }
                                    
                                    if notifyMe {
                                        DispatchQueue.main.async {
                                            notificationManager.showCustomNotification()
                                        }
                                    }
                                    
                                    localFilesManager.addItem(generationResultImage)
                                case .failure(_):
                                    showProcessingView = false
                                    presentErrorAlert = true
                                }
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
                        prompt.isEmpty ? LinearGradient(gradient: Gradient(colors: [.backgroundGray]), startPoint: .leading, endPoint: .trailing) : LinearGradient(gradient: Gradient(colors: [.buttonGratient1, .buttonGradient2]), startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    
                    .padding(.top, 10)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .disabled(prompt.isEmpty)
                    .fullScreenCover(isPresented: $presentPaywall) {
                        Paywall()
                    }
                }
                
                
                if presentErrorAlert {
                    ZStack {
                        BlurView(style: .systemUltraThinMaterialDark)
                            .ignoresSafeArea()
                        ErrorAlert(presentAlert: $presentErrorAlert, textAlert: "If you get an error, check your prompts or contact support")
                    }
                }
                
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    Text("")
                }
                
                
            }.fullScreenCover(isPresented: $showProcessingView) {
                ProcessingView(notifyMe: $notifyMe )
                    .environmentObject(notificationManager)
            }
        }
    }
}


#Preview {
    GeneratingView()
}
