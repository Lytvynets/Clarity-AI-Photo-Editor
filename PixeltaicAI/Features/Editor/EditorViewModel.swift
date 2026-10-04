
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


    var runCost: Int {
        if tool == .resize && resize.fit == .aiExtend { return 2 }
        return tool.runCost
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
        guard tool == .enhance, let source = sourcePixels else { return nil }
        let scale = CGFloat(max(1, enhance.scale))
        let longest = max(source.width, source.height)
        let allowedInput = min(longest, 4096 / scale)
        let ratio = allowedInput / max(longest, 1)
        let width = Int((source.width * ratio * scale).rounded())
        let height = Int((source.height * ratio * scale).rounded())
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

        runTask = Task { [weak self] in
            guard let self else { return }
            do {
                let outcome = try await self.perform(data: data)
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
            } catch is CancellationError {
                refund()
                self.phase = .ready
            } catch let error as ClaidError {
                refund()
                self.errorMessage = error.errorDescription
                self.phase = .ready
                Haptics.error()
            } catch {
                refund()
                self.errorMessage = "Something went wrong. Please try again."
                self.phase = .ready
                Haptics.error()
            }
        }
    }

    private func plan() -> RequestPlan? {
        switch tool {
        case .enhance: return ToolRequestBuilder.enhance(enhance)
        case .background: return ToolRequestBuilder.background(background)
        case .blur: return ToolRequestBuilder.blur(blur)
        case .color: return ToolRequestBuilder.color(color)
        case .resize: return ToolRequestBuilder.resize(resize, source: sourcePixels)
        case .magic, .create: return nil
        }
    }

    private func perform(data: Data) async throws -> Outcome {
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

        guard let plan = plan() else { throw ClaidError.badResponse }
        let side = plan.maxInputSide
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
