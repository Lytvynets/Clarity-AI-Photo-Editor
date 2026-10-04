

import SwiftUI


enum UpscaleMode: String, CaseIterable, Identifiable {
    case photo, faces, smartEnhance, digitalArt

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photo: return "Photo"
        case .faces: return "Portrait"
        case .smartEnhance: return "Smart"
        case .digitalArt: return "Illustration"
        }
    }

    var detail: String {
        switch self {
        case .photo: return "Best for everyday photos and old prints."
        case .faces: return "Rebuilds faces with natural skin and eyes."
        case .smartEnhance: return "Adds fine detail to already good images."
        case .digitalArt: return "Keeps lines crisp on art, logos and screenshots."
        }
    }

    var apiValue: String {
        switch self {
        case .photo: return "photo"
        case .faces: return "faces"
        case .smartEnhance: return "smart_enhance"
        case .digitalArt: return "digital_art"
        }
    }
}

enum DenoiseLevel: String, CaseIterable, Identifiable {
    case off, auto, moderate, strong

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: return "Off"
        case .auto: return "Auto"
        case .moderate: return "Medium"
        case .strong: return "Strong"
        }
    }

    var apiValue: String? {
        switch self {
        case .off: return nil
        case .auto: return "auto"
        case .moderate: return "moderate"
        case .strong: return "strong"
        }
    }
}

struct EnhanceParams: Equatable {
    var mode: UpscaleMode = .photo
    var scale: Int = 2
    var denoise: DenoiseLevel = .auto
    var polish: Bool = true
}


enum SubjectCategory: String, CaseIterable, Identifiable {
    case general, products, cars

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "Anything"
        case .products: return "Product"
        case .cars: return "Car"
        }
    }

    var apiValue: String { rawValue }
}

struct BackgroundParams: Equatable {
    var transparent: Bool = true
    var color: Color = .white
    var category: SubjectCategory = .general
    var keepOnly: String = ""
    var padding: Double = 0
}


enum BlurStyle: String, CaseIterable, Identifiable {
    case regular, lens

    var id: String { rawValue }
    var title: String { self == .lens ? "Lens" : "Soft" }
    var apiValue: String { rawValue }
}

enum BlurLevel: String, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }
    var title: String {
        switch self {
        case .low: return "Light"
        case .medium: return "Medium"
        case .high: return "Strong"
        }
    }
    var apiValue: String { rawValue }
}

struct BlurParams: Equatable {
    var style: BlurStyle = .lens
    var level: BlurLevel = .medium
    var category: SubjectCategory = .general
}


struct ColorParams: Equatable {
    var hdr: Double = 0
    var exposure: Double = 0
    var saturation: Double = 0
    var contrast: Double = 0
    var sharpness: Double = 0

    var isNeutral: Bool {
        hdr < 1 && abs(exposure) < 1 && abs(saturation) < 1 && abs(contrast) < 1 && sharpness < 1
    }
}

struct ColorPreset: Identifiable {
    let title: String
    let icon: String
    let params: ColorParams

    var id: String { title }

    static let all: [ColorPreset] = [
        ColorPreset(title: "Auto", icon: "wand.and.stars", params: ColorParams(hdr: 100)),
        ColorPreset(title: "Vivid", icon: "drop.fill", params: ColorParams(hdr: 45, saturation: 28, contrast: 10)),
        ColorPreset(title: "Bright", icon: "sun.max.fill", params: ColorParams(hdr: 30, exposure: 30)),
        ColorPreset(title: "Moody", icon: "moon.fill", params: ColorParams(exposure: -15, saturation: -10, contrast: 28)),
        ColorPreset(title: "Crisp", icon: "triangle.fill", params: ColorParams(contrast: 12, sharpness: 45))
    ]
}


enum ResizeMode: String, CaseIterable, Identifiable {
    case preset, custom, percent

    var id: String { rawValue }
    var title: String {
        switch self {
        case .preset: return "Presets"
        case .custom: return "Custom"
        case .percent: return "Scale"
        }
    }
}

enum ResizeFit: String, CaseIterable, Identifiable {
    case smartCrop, fitInside, fill, aiExtend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .smartCrop: return "Smart crop"
        case .fitInside: return "Fit inside"
        case .fill: return "Fill"
        case .aiExtend: return "AI extend"
        }
    }

    var icon: String {
        switch self {
        case .smartCrop: return "viewfinder"
        case .fitInside: return "arrow.down.right.and.arrow.up.left"
        case .fill: return "rectangle.fill"
        case .aiExtend: return "sparkles"
        }
    }

    var detail: String {
        switch self {
        case .smartCrop: return "Crops around the main subject so nothing important is cut."
        case .fitInside: return "Keeps the whole photo inside the new size, no cropping."
        case .fill: return "Scales the photo until it fully covers the new size."
        case .aiExtend: return "AI paints new background to fill the extra space."
        }
    }

    var apiValue: Any {
        switch self {
        case .smartCrop: return ["crop": "smart"]
        case .fitInside: return "bounds"
        case .fill: return "cover"
        case .aiExtend: return "outpaint"
        }
    }
}

struct ResizePreset: Identifiable, Equatable {
    let name: String
    let width: Int
    let height: Int

    var id: String { name }
    var sizeLabel: String { "\(width) × \(height)" }
    var ratio: CGFloat { CGFloat(width) / CGFloat(height) }

    static let all: [ResizePreset] = [
        ResizePreset(name: "Square", width: 1080, height: 1080),
        ResizePreset(name: "Portrait 4:5", width: 1080, height: 1350),
        ResizePreset(name: "Story / Reels", width: 1080, height: 1920),
        ResizePreset(name: "Landscape 16:9", width: 1920, height: 1080),
        ResizePreset(name: "Classic 4:3", width: 1600, height: 1200),
        ResizePreset(name: "Wide banner", width: 1500, height: 500),
        ResizePreset(name: "Avatar", width: 512, height: 512),
        ResizePreset(name: "4K wallpaper", width: 3840, height: 2160)
    ]
}

struct ResizeParams: Equatable {
    var mode: ResizeMode = .preset
    var preset: ResizePreset = ResizePreset.all[0]
    var widthText: String = ""
    var heightText: String = ""
    var percent: Double = 200
    var fit: ResizeFit = .smartCrop
}


struct RequestPlan {
    var operations: [String: Any]
    var output: [String: Any]
    var maxInputSide: CGFloat
    var transparent: Bool
    var title: String
}

enum ToolRequestBuilder {

    static func jpegOutput(quality: Int = 92) -> [String: Any] {
        ["format": ["type": "jpeg", "quality": quality]]
    }

    static var pngOutput: [String: Any] {
        ["format": ["type": "png"]]
    }


    static func enhance(_ params: EnhanceParams) -> RequestPlan {
        var restorations: [String: Any] = ["upscale": params.mode.apiValue]
        if let decompress = params.denoise.apiValue { restorations["decompress"] = decompress }
        if params.polish { restorations["polish"] = true }

        let scale = max(1, params.scale)
        let percent = "\(scale * 100)%"
        let operations: [String: Any] = [
            "restorations": restorations,
            "resizing": ["width": percent, "height": percent]
        ]
        let side = CGFloat(4096 / scale)
        return RequestPlan(operations: operations,
                           output: jpegOutput(),
                           maxInputSide: side,
                           transparent: false,
                           title: scale == 1 ? "Restored photo" : "Enhanced \(scale)×")
    }


    static func background(_ params: BackgroundParams) -> RequestPlan {
        var remove: [String: Any] = [:]
        let keep = params.keepOnly.trimmed
        if keep.isEmpty {
            remove["category"] = params.category.apiValue
        } else {
            remove["selective"] = ["object_to_keep": keep]
        }
        let padded = params.padding >= 1
        if padded { remove["clipping"] = true }

        let colorValue = params.transparent ? "transparent" : params.color.hexString
        var operations: [String: Any] = [
            "background": ["remove": remove, "color": colorValue]
        ]
        if padded { operations["padding"] = "\(Int(params.padding.rounded()))%" }

        return RequestPlan(operations: operations,
                           output: params.transparent ? pngOutput : jpegOutput(),
                           maxInputSide: 4096,
                           transparent: params.transparent,
                           title: params.transparent ? "Cutout" : "New background")
    }


    static func blur(_ params: BlurParams) -> RequestPlan {
        let blur: [String: Any] = [
            "category": params.category.apiValue,
            "type": params.style.apiValue,
            "level": params.level.apiValue
        ]
        let operations: [String: Any] = ["background": ["blur": blur]]
        return RequestPlan(operations: operations,
                           output: jpegOutput(),
                           maxInputSide: 4096,
                           transparent: false,
                           title: "Background blur")
    }


    static func color(_ params: ColorParams) -> RequestPlan {
        var adjustments: [String: Any] = [:]
        if params.hdr >= 1 { adjustments["hdr"] = Int(params.hdr.rounded()) }
        if abs(params.exposure) >= 1 { adjustments["exposure"] = Int(params.exposure.rounded()) }
        if abs(params.saturation) >= 1 { adjustments["saturation"] = Int(params.saturation.rounded()) }
        if abs(params.contrast) >= 1 { adjustments["contrast"] = Int(params.contrast.rounded()) }
        if params.sharpness >= 1 { adjustments["sharpness"] = Int(params.sharpness.rounded()) }

        return RequestPlan(operations: ["adjustments": adjustments],
                           output: jpegOutput(quality: 95),
                           maxInputSide: 4096,
                           transparent: false,
                           title: "Color & light")
    }


    static func resize(_ params: ResizeParams, source: CGSize?) -> RequestPlan {
        var width: Any = "auto"
        var height: Any = "auto"
        var fit: Any = "bounds"
        var targetLongest: CGFloat = 0
        var maxInput: CGFloat = 4096

        switch params.mode {
        case .preset:
            width = params.preset.width
            height = params.preset.height
            fit = params.fit.apiValue
            targetLongest = CGFloat(max(params.preset.width, params.preset.height))
        case .custom:
            let w = Int(params.widthText.trimmed)
            let h = Int(params.heightText.trimmed)
            if let w { width = w }
            if let h { height = h }
            fit = (w != nil && h != nil) ? params.fit.apiValue : "bounds"
            targetLongest = CGFloat(max(w ?? 0, h ?? 0))
        case .percent:
            let percent = "\(Int(params.percent.rounded()))%"
            width = percent
            height = percent
            fit = "bounds"
            if let source {
                targetLongest = max(source.width, source.height) * CGFloat(params.percent / 100)
            }
            if params.percent > 100 {
                maxInput = 4096 / CGFloat(params.percent / 100)
            }
        }

        var operations: [String: Any] = [
            "resizing": ["width": width, "height": height, "fit": fit]
        ]

        if let source, targetLongest > max(source.width, source.height) * 1.02 {
            operations["restorations"] = ["upscale": "smart_resize"]
        }

        return RequestPlan(operations: operations,
                           output: jpegOutput(),
                           maxInputSide: max(256, maxInput),
                           transparent: false,
                           title: "Resized photo")
    }
}
