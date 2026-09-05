//
//  LocalFilesManager.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 04.12.2024.
//

import Foundation
import UIKit
import Photos


class LocalFilesManager: ObservableObject {
    
    @Published var resultsArray: [ResultImageModel] = [] {
        didSet {
            saveArrayToDefaults()
        }
    }
    
    private let userDefaultsKey = "resultImage"
    
    
    init() {
        loadArrayFromDefaults()
    }
    
    
    func addItem(_ item: ResultImageModel) {
        DispatchQueue.main.async {
            self.resultsArray.append(item)
        }
    }
    
    
    func deleteItem(_ item: ResultImageModel, completion: @escaping (Bool) -> () ) {
        DispatchQueue.main.async {
            self.resultsArray.removeAll { $0 == item }
            completion(true)
        }
    }
    
    
    private func saveArrayToDefaults() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(resultsArray) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    
    private func loadArrayFromDefaults() {
        let decoder = JSONDecoder()
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedArray = try? decoder.decode([ResultImageModel].self, from: savedData) {
            self.resultsArray = decodedArray
        }
    }
}
