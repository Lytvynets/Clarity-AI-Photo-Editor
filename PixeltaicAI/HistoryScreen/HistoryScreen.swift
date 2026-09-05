//
//  HistoryScreen.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 22.10.2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct HistoryScreen: View {
    
    @EnvironmentObject var localFilesManager: LocalFilesManager
    @State private var isPresentedResultScreen = false
    @State private var selectedResult: Int = 0
    
    var body: some View {
        
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ]
        
        NavigationStack {
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [.black, .backgroundGradient]),
                               startPoint: .bottomLeading,
                               endPoint: .topTrailing)
                .ignoresSafeArea()
                .navigationTitle("History")
                
                VStack {
                    
                    ScrollView {
                        
                        LazyVGrid(columns: columns) {
                            
                            ForEach(Array(localFilesManager.resultsArray.enumerated()), id: \.1.outputURL) { index, result in
                                WebImage(url: URL(string: result.outputURL))
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: UIScreen.main.bounds.width / 4,
                                           height: UIScreen.main.bounds.width / 4)
                                
                                    .cornerRadius(20)
                                    .onTapGesture {
                                        selectedResult = index
                                        DispatchQueue.main.async {
                                            isPresentedResultScreen = true
                                        }
                                        
                                    }
                            }
                        }
                    }.scrollIndicators(.hidden)
                }.padding(.horizontal)
            }
        }   .fullScreenCover(isPresented: Binding(
            get: { isPresentedResultScreen },
            set: { newValue in
                isPresentedResultScreen = newValue
                if !newValue {
                    selectedResult = 0
                }
            }
        )) {
            if selectedResult >= 0 && selectedResult < localFilesManager.resultsArray.count {
                ResultEditImageView(resultImage: localFilesManager.resultsArray[selectedResult])
                    .environmentObject(localFilesManager)
            } else {
                Text("Invalid index")
            }
        }
    }
}

#Preview {
    HistoryScreen()
}
