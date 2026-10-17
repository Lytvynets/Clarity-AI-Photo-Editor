
import SwiftUI
import PhotosUI

enum EditorPhase: Equatable {
    case empty
    case ready
    case processing
    case result
}

@MainActor
final class EditorViewModel: ObservableObject {

    @Published var tool: Tool {
        didSet { if tool == .enhance { applyAutoModeIfNeeded() } }
    }
    @Published private(set) var phase: EditorPhase = .empty
    @Published private(set) var originalImage: UIImage?
    @Published private(set) var resultImage: UIImage?
    @Published private(set) var resultIsTransparent = false
    @Published private(set) var savedItem: LibraryItem?
    @Published private(set) var isLoadingPhoto = false
    @Published private(set) var faceHint: String?
    @Published var statusText = ""
    @Published var errorMessage: String?
    /// Kept in sync by the view; free photos are sent to the AI at a smaller size (see `FreeTier`).
    @Published var isPro = false

    @Published var enhance = EnhanceParams()
    @Published var background = BackgroundParams()
    @Published var blur = BlurParams()
    @Published var color = ColorParams()
    @Published var resize = ResizeParams()
    @Published var magicPrompt = ""

    private(set) var originalData: Data?
    private(set) var resultData: Data?

    private var sourcePixels: CGSize?
    private var runTask: Task<Void, Never>?
    private var facesDetected: Bool?
    private var autoModeApplied = false

    init(tool: Tool) {
        self.tool = tool
    }


    /// Run units this run costs. Enhance and upscaling resizes are priced by the size of the result
    /// (the AI service charges by output size); every other tool has a fixed price.
    var runCost: Int {
        switch tool {
        case .enhance: return enhanceCost
        case .resize: return resizeCost
        default: return tool.runCost
        }
    }

    /// Free runs are limited to the free upscale; subscribers get everything they asked for.
    private var effectiveEnhanceScale: Int {
        let wanted = max(1, enhance.scale)
        return isPro ? wanted : min(wanted, FreeTier.maxUpscaleFree)
    }

    /// Size of the photo that gets uploaded and of the enhanced result, for the current plan.
    private var enhanceSizes: (upload: CGSize, result: CGSize)? {
        guard let source = sourcePixels, source.width > 0, source.height > 0 else { return nil }
        let scale = CGFloat(effectiveEnhanceScale)
        let longest = max(source.width, source.height)
        var allowedInput = min(longest, 4096 / scale)
        if !isPro && Self.usesFreeInputCap(.enhance) {
            allowedInput = min(allowedInput, Self.freeUploadSide(for: .enhance, scale: effectiveEnhanceScale))
        }
        let ratio = allowedInput / longest
        let upload = CGSize(width: source.width * ratio, height: source.height * ratio)
        let result = CGSize(width: upload.width * scale, height: upload.height * scale)
        return (upload, result)
    }

    private var enhanceCost: Int {
        let base = Limits.enhance
        guard let sizes = enhanceSizes else { return base }
        let megapixels = Double(sizes.result.width * sizes.result.height) / 1_000_000
        // The extra "sharpen details" pass costs one more credit, so it is a Pro option.
        let polish = (isPro && enhance.polish) ? 1 : 0
        return max(base, Limits.upscaleUnits(megapixels: megapixels)) + polish
    }

    private var resizeCost: Int {
        let request = ToolRequestBuilder.resize(resize, source: sourcePixels)
        var units = 0
        let resizing = request.operations["resizing"] as? [String: Any]
        if let fit = resizing?["fit"] as? String, fit == "outpaint" {
            units += Limits.aiExtend
        }
        if request.operations["restorations"] != nil,
           let target = ToolRequestBuilder.resizeTarget(resize, source: sourcePixels) {
            let megapixels = Double(target.width * target.height) / 1_000_000
            units += Limits.upscaleUnits(megapixels: megapixels)
        }
        return max(1, units)
    }

    /// Megapixels the AI has to produce for this run (Enhance and upscaling resizes), for analytics.
    private var outputMegapixels: Double? {
        switch tool {
        case .enhance:
            guard let sizes = enhanceSizes else { return nil }
            return Double(sizes.result.width * sizes.result.height) / 1_000_000
        case .resize:
            guard let target = ToolRequestBuilder.resizeTarget(resize, source: sourcePixels) else { return nil }
            return Double(target.width * target.height) / 1_000_000
        default:
            return nil
        }
    }

    var actionTitle: String {
        switch tool {
        case .enhance: return "Enhance photo"
        case .background: return "Remove background"
        case .blur: return "Blur background"
        case .magic: return "Apply magic"
        case .color: return "Apply adjustments"
        case .resize: return "Resize photo"
        case .create: return "Create"
        }
    }

    var validationMessage: String? {
        switch tool {
        case .magic:
            return magicPrompt.trimmed.count < 3 ? "Describe the change in a few words first." : nil
        case .color:
            return color.isNeutral ? "Pick a preset or move at least one slider." : nil
        case .resize:
            guard resize.mode == .custom else { return nil }
            let width = Int(resize.widthText.trimmed)
            let height = Int(resize.heightText.trimmed)
            if width == nil && height == nil { return "Enter a width or a height." }
            for value in [width, height].compactMap({ $0 }) where value < 16 || value > 8000 {
                return "Use sizes between 16 and 8000 px."
            }
            return nil
        default:
            return nil
        }
    }

    var enhanceOutputText: String? {
        guard tool == .enhance, let sizes = enhanceSizes else { return nil }
        let width = Int(sizes.result.width.rounded())
        let height = Int(sizes.result.height.rounded())
        return "\(width) × \(height) px"
    }


    func loadPhoto(from item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Couldn't open that photo. Try another one."
                return
            }
            setPhoto(data: data)
        } catch {
            errorMessage = "Couldn't open that photo. Try another one."
        }
    }

    func setPhoto(data: Data) {
        guard let display = ImageIOHelper.downsampledImage(data: data, maxPixel: 2048) else {
            errorMessage = "This file isn't a supported image."
            Haptics.error()
            return
        }
        runTask?.cancel()
        originalData = data
        originalImage = display
        sourcePixels = ImagePrep.pixelSize(of: data)
        clearResult()
        errorMessage = nil
        faceHint = nil
        facesDetected = nil
        autoModeApplied = false
        phase = .ready
        Haptics.tap()

        let pixels = sourcePixels.map { Int(($0.width * $0.height / 1_000_000).rounded()) } ?? 0
        AppAnalytics.log(AppAnalytics.Event.photoPicked, ["tool": tool.id, "megapixels": pixels])

        Task {
            let found = await ImagePrep.hasFaces(in: display)
            self.facesDetected = found
            self.applyAutoModeIfNeeded()
        }
    }

    private func applyAutoModeIfNeeded() {
        guard tool == .enhance, facesDetected == true, !autoModeApplied else { return }
        autoModeApplied = true
        if enhance.mode == .photo {
            enhance.mode = .faces
            faceHint = "Faces detected · Portrait mode selected"
        }
    }

    private func clearResult() {
        resultImage = nil
        resultData = nil
        resultIsTransparent = false
        savedItem = nil
    }


    func backToReady() {
        guard phase == .result else { return }
        clearResult()
        phase = .ready
    }

    func startOver() {
        runTask?.cancel()
        clearResult()
        originalData = nil
        originalImage = nil
        sourcePixels = nil
        errorMessage = nil
        phase = .empty
    }

    func continueEditing(with newTool: Tool) {
        guard let data = resultData, let image = resultImage else { return }
        originalData = data
        originalImage = image
        sourcePixels = ImagePrep.pixelSize(of: data)
        clearResult()
        errorMessage = nil
        facesDetected = nil
        autoModeApplied = true
        tool = newTool
        phase = .ready
        Haptics.tap()
    }

    func cancel() {
        runTask?.cancel()
    }

    private struct Outcome {
        let data: Data
        let title: String
        let transparent: Bool
        let prompt: String?
    }

    /// Tools whose cost grows with photo size; free users get a smaller upload there.
    /// Resize and Color keep full size because their result depends on the exact pixel dimensions.
    private static func usesFreeInputCap(_ tool: Tool) -> Bool {
        tool == .enhance || tool == .background || tool == .blur
    }

    /// Longest side (px) a free photo is uploaded at. Enhance is priced by the size of the result,
    /// so a smaller upscale may start from a bigger photo and still end at the same free size.
    private static func freeUploadSide(for tool: Tool, scale: Int) -> CGFloat {
        let cap = CGFloat(FreeTier.maxInputSide)
        guard tool == .enhance else { return cap }
        return cap * CGFloat(FreeTier.maxUpscaleFree) / CGFloat(max(1, scale))
    }

    func run(library: LibraryStore, isPro: Bool, refund: @escaping () -> Void) {
        guard phase == .ready, let data = originalData else {
            refund()
            return
        }
        if !isPro && enhance.scale > FreeTier.maxUpscaleFree {
            enhance.scale = FreeTier.maxUpscaleFree
        }

        errorMessage = nil
        statusText = "Uploading photo…"
        phase = .processing

        let usedTool = tool
        let beforeImage = originalImage
        let startedAt = Date()
        var startInfo: [String: Any] = ["tool": usedTool.id, "cost": runCost]
        if let megapixels = outputMegapixels {
            startInfo["out_mp"] = (megapixels * 10).rounded() / 10
        }
        let runInfo = startInfo
        AppAnalytics.log(AppAnalytics.Event.runStart, runInfo)

        runTask = Task { [weak self] in
            guard let self else { return }
            do {
                let outcome = try await self.perform(data: data, isPro: isPro)
                try Task.checkCancellation()

                guard let display = ImageIOHelper.downsampledImage(data: outcome.data, maxPixel: 2400) else {
                    throw ClaidError.badResponse
                }
                self.resultData = outcome.data
                self.resultImage = display
                self.resultIsTransparent = outcome.transparent && outcome.data.isPNG
                self.phase = .result
                Haptics.success()

                let item = await library.add(resultData: outcome.data,
                                             before: beforeImage,
                                             tool: usedTool,
                                             title: outcome.title,
                                             prompt: outcome.prompt,
                                             isTransparent: self.resultIsTransparent)
                self.savedItem = item
                var info = runInfo
                info["seconds"] = Int(Date().timeIntervalSince(startedAt).rounded())
                AppAnalytics.log(AppAnalytics.Event.runSuccess, info)
            } catch is CancellationError {
                refund()
                self.phase = .ready
                AppAnalytics.log(AppAnalytics.Event.runCancel, runInfo)
            } catch let error as ClaidError {
                refund()
                self.errorMessage = error.errorDescription
                self.phase = .ready
                Haptics.error()
                var info = runInfo
                info["error"] = error.analyticsCode
                AppAnalytics.log(AppAnalytics.Event.runFail, info)
            } catch {
                refund()
                self.errorMessage = "Something went wrong. Please try again."
                self.phase = .ready
                Haptics.error()
                var info = runInfo
                info["error"] = "unknown"
                AppAnalytics.log(AppAnalytics.Event.runFail, info)
            }
        }
    }

    private func plan(isPro: Bool) -> RequestPlan? {
        switch tool {
        case .enhance:
            var params = enhance
            if !isPro {
                // Free runs: no more than the free upscale and no extra polish pass.
                params.scale = min(max(1, params.scale), FreeTier.maxUpscaleFree)
                params.polish = false
            }
            return ToolRequestBuilder.enhance(params)
        case .background: return ToolRequestBuilder.background(background)
        case .blur: return ToolRequestBuilder.blur(blur)
        case .color: return ToolRequestBuilder.color(color)
        case .resize: return ToolRequestBuilder.resize(resize, source: sourcePixels)
        case .magic, .create: return nil
        }
    }

    private func perform(data: Data, isPro: Bool) async throws -> Outcome {
        let client = ClaidClient.shared

        if tool == .magic {
            let prompt = magicPrompt.trimmed
            let jpeg = await Task.detached(priority: .userInitiated) { () -> Data? in
                ImagePrep.uploadJPEG(from: data, maxSide: 2048)
            }.value
            guard let jpeg else { throw ClaidError.badResponse }

            statusText = "Uploading photo…"
            let hosted = try await client.upload(imageData: jpeg)
            try Task.checkCancellation()

            let url = try await client.aiEdit(inputURL: hosted, prompt: prompt) { [weak self] status in
                Task { @MainActor in self?.statusText = status }
            }
            try Task.checkCancellation()
            statusText = "Downloading result…"
            let result = try await client.download(url)
            return Outcome(data: result, title: prompt, transparent: false, prompt: prompt)
        }

        guard let plan = plan(isPro: isPro) else { throw ClaidError.badResponse }
        var uploadSide: CGFloat = plan.maxInputSide
        if !isPro && Self.usesFreeInputCap(tool) {
            let scale = min(max(1, enhance.scale), FreeTier.maxUpscaleFree)
            uploadSide = min(uploadSide, Self.freeUploadSide(for: tool, scale: scale))
        }
        let side = uploadSide
        let jpeg = await Task.detached(priority: .userInitiated) { () -> Data? in
            ImagePrep.uploadJPEG(from: data, maxSide: side, quality: 0.93)
        }.value
        guard let jpeg else { throw ClaidError.badResponse }

        statusText = "Processing with AI…"
        let url = try await client.edit(imageData: jpeg, operations: plan.operations, output: plan.output)
        try Task.checkCancellation()
        statusText = "Downloading result…"
        let result = try await client.download(url)
        return Outcome(data: result, title: plan.title, transparent: plan.transparent, prompt: nil)
    }
}
