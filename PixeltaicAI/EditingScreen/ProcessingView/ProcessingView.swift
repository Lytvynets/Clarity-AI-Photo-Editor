//
//  ProcessingView.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 04.12.2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProcessingView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var notifyMe: Bool
    @EnvironmentObject var notificationManager: NotificationManager
    
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing)
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Generating...")
                .toolbar {
                    Button {
                        dismiss()
                    }label: {
                        Image("close 1")
                    }
                }
                
                VStack {
                    
                    if let gifURL = Bundle.main.url(forResource: "Animation - 1733312081805", withExtension: "gif") {
                        WebImage(url: gifURL)
                            .padding(.bottom, 90)
                    } else {
                        Text("GIF not found")
                            .foregroundColor(.white)
                            .background(Color.black)
                    }
                }
                
                VStack {
                    
                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        notifyMe = true
                        
                    }label: {
                        Text("Notify me")
                            .font(.custom("Lato-Italic", size: AdaptiveFontSize.shared.medium))
                            .foregroundStyle(notifyMe ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(notifyMe ? .white : .clear)
                            .background(
                                BlurView(style: .systemUltraThinMaterialDark)
                                    .opacity(0.7)
                                    .blur(radius: 1)
                            )
                            .clipShape(.capsule)
                    }.padding(.bottom)
                        .padding(.horizontal, 30)
                }
            }
        }.onAppear {
            notifyMe = false
        }
    }
}

#Preview {
    //    @State var notifyMe: Bool = true
    //    ProcessingView( notifyMe: $notifyMe)
}
