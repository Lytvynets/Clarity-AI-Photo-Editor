//
//  ResizingParameters.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 30.11.2024.
//

import Foundation

enum ResizingType {
    case empty
    case auto
    case pixels
    case percentage
}


enum FitType {
    case crop
    case bounds
    case cover
    case canvas
    case outpaint
}
