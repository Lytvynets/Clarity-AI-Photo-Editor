//
//  EditingViewMode.swift
//  PixeltaicAI
//
//  Created by Vlad Lytvynets on 04.12.2024.
//

import Foundation

enum EditingViewMode {
    case restorations
    case resizing
    case padding
    case colorAdjustments
    case background
}

class EditingViewModObserver: ObservableObject {
    @Published var editingViewMod: EditingViewMode = .restorations
}
