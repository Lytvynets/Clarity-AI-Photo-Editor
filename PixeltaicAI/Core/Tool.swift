

import SwiftUI

enum Tool: String, CaseIterable, Identifiable {
    case enhance, background, blur, magic, color, resize, create

    var id: String { rawValue }

    static let photoTools: [Tool] = [.enhance, .background, .blur, .magic, .color, .resize]

    var title: String {
        switch self {
        case .enhance: return "Enhance"
        case .background: return "Remove Background"
        case .blur: return "Blur Background"
        case .magic: return "Magic Edit"
        case .color: return "Color & Light"
        case .resize: return "Resize & Crop"
        case .create: return "Create"
        }
    }

    var shortTitle: String {
        switch self {
        case .enhance: return "Enhance"
        case .background: return "Cutout"
        case .blur: return "Blur"
        case .magic: return "Magic"
        case .color: return "Color"
        case .resize: return "Resize"
        case .create: return "Create"
        }
    }

    var subtitle: String {
        switch self {
        case .enhance: return "Sharpen, denoise and upscale up to 4×"
        case .background: return "Clean cutouts in one tap"
        case .blur: return "Studio-style depth of field"
        case .magic: return "Edit any photo with words"
        case .color: return "HDR, exposure, contrast and more"
        case .resize: return "Social presets, smart crop, AI extend"
        case .create: return "Turn a prompt into images"
        }
    }

    var symbol: String {
        switch self {
        case .enhance: return "wand.and.stars"
        case .background: return "scissors"
        case .blur: return "camera.aperture"
        case .magic: return "sparkles"
        case .color: return "slider.horizontal.3"
        case .resize: return "crop"
        case .create: return "wand.and.rays"
        }
    }

    var colors: [Color] {
        switch self {
        case .enhance: return [Theme.violet, Theme.blue]
        case .background: return [Theme.pink, Theme.orange]
        case .blur: return [Theme.cyan, Theme.blue]
        case .magic: return [Theme.fuchsia, Theme.violet]
        case .color: return [Theme.orange, Theme.gold]
        case .resize: return [Theme.mint, Theme.cyan]
        case .create: return [Theme.fuchsia, Theme.pink]
        }
    }

    var runCost: Int {
        switch self {
        case .enhance, .magic, .create: return 2
        case .background, .blur, .color, .resize: return 1
        }
    }

    var pickerHint: String {
        switch self {
        case .enhance: return "Pick an old, blurry or low-resolution photo"
        case .background: return "Pick a photo with a clear subject"
        case .blur: return "Pick a photo to add depth of field"
        case .magic: return "Pick a photo, then describe the change"
        case .color: return "Pick a photo to fine-tune light and color"
        case .resize: return "Pick a photo to resize for any platform"
        case .create: return ""
        }
    }
}
