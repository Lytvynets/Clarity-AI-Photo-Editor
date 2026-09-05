//
//  ResultImageModel.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 04.12.2024.
//

import Foundation


struct ResultImageModel: Codable {
    private var resultID = UUID()
    var inputURL: String
    var outputURL: String
    var isGenerated: Bool
    
    init(inputURL: String, outputURL: String, isGenerated: Bool) {
         self.inputURL = inputURL
         self.outputURL = outputURL
         self.isGenerated = isGenerated
     }
    
}


extension ResultImageModel: Equatable {
   static func == (lhs: ResultImageModel, rhs: ResultImageModel) -> Bool {
       return lhs.resultID == rhs.resultID
    }
}
