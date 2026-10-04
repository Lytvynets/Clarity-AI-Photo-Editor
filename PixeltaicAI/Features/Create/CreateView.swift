
import SwiftUI

enum CreateStyle: String, CaseIterable, Identifiable {
    case none, photo, cinematic, anime, render3D, watercolor, cyberpunk, minimal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "None"
        case .photo: return "Photo"
        case .cinematic: return "Cinematic"
        case .anime: return "Anime"
        case .render3D: return "3D"
        case .watercolor: return "Watercolor"
        case .cyberpunk: return "Cyberpunk"
        case .minimal: return "Minimal"
        }
    }

    var suffix: String {
        switch self {
        case .none: return ""
        case .photo: return "ultra realistic photo, natural light, sharp focus, 35mm"
        case .cinematic: return "cinematic lighting, dramatic composition, film still, shallow depth of field"
        case .anime: return "anime style illustration, clean line art, vibrant colors"
        case .render3D: return "3D render, soft studio lighting, octane render, highly detailed"
        case .watercolor: return "watercolor painting, soft washes, paper texture"
        case .cyberpunk: return "cyberpunk style, neon lights, rain, futuristic city"
        case .minimal: return "minimalist flat illustration, simple shapes, pastel palette"
        }
    }
}

@MainActor
final class CreateViewModel: ObservableObject {

    enum Phase { case input, generating, results }

    struct Generated: Identifiable {
        let id = UUID()
        let image: UIImage
        let data: Data
    }

    @Published var prompt = ""
    @Published var style: CreateStyle = .none
    @Published var count = 1
    @Published var strictness: Double = 6
    @Published private(set) var phase: Phase = .input
    @Published private(set) var results: [Generated] = []
    @Published var selectedIndex = 0
    @Published var statusText = ""
    @Published var errorMessage: String?

    private var task: Task<Void, Never>?

    let ideas = [
        "A cozy cabin in a snowy forest at dusk",
        "Astronaut riding a horse on Mars",
        "Cute fox wearing a spacesuit",
        "Neon-lit Tokyo street in the rain",
        "Lighthouse at sunrise above a stormy sea",
        "Futuristic city floating in the clouds",
        "Steampunk owl made of brass gears",
        "Tiny island shaped like a sleeping dragon"
    ]

    var finalPrompt: String {
        let base = prompt.trimmed
        return style.suffix.isEmpty ? base : "\(base), \(style.suffix)"
    }

    var validationMessage: String? {
        prompt.trimmed.count < 3 ? "Describe what you want to see in a few words." : nil
    }

    func surprise() {
        let options = ideas.filter { $0 != prompt }
        prompt = options.randomElement() ?? ideas[0]
        Haptics.select()
    }

    func reset() {
        task?.cancel()
        results = []
        phase = .input
    }

    func cancel() {
        task?.cancel()
    }

    func generate(library: LibraryStore, isPro: Bool, refund: @escaping () -> Void) {
        guard phase == .input else {
            refund()
            return
        }
        errorMessage = nil
        statusText = "Sending your prompt…"
        phase = .generating

        let requested = isPro ? max(1, min(count, FreeTier.generateImagesPro)) : FreeTier.generateImagesFree
        let sent = finalPrompt
        let shown = prompt.trimmed
        let guidance = strictness

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let client = ClaidClient.shared
                let urls = try await client.generate(prompt: sent, count: requested, guidance: guidance)
                var made: [Generated] = []
                for (index, url) in urls.enumerated() {
                    try Task.checkCancellation()
                    self.statusText = urls.count > 1 ? "Downloading image \(index + 1) of \(urls.count)…" : "Downloading image…"
                    let data = try await client.download(url)
                    if let image = ImageIOHelper.downsampledImage(data: data, maxPixel: 2048), !image.looksCompletelyBlack {
                        made.append(Generated(image: image, data: data))
                    }
                }
                guard !made.isEmpty else { throw ClaidError.contentFiltered }

                for generated in made {
                    await library.add(resultData: generated.data,
                                      before: nil,
                                      tool: .create,
                                      title: shown,
                                      prompt: shown)
                }
                self.results = made
                self.selectedIndex = 0
                self.phase = .results
                Haptics.success()
            } catch is CancellationError {
                refund()
                self.phase = .input
            } catch let error as ClaidError {
                refund()
                self.errorMessage = error.errorDescription
                self.phase = .input
                Haptics.error()
            } catch {
                refund()
                self.errorMessage = "Something went wrong. Please try again."
                self.phase = .input
                Haptics.error()
            }
        }
    }
}

struct CreateView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var router: Router

    @StateObject private var vm = CreateViewModel()
    @State private var gateRequest: RunGateRequest?
    @State private var showPaywall = false
    @State private var toast: String?
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showPermissionAlert = false
    @State private var isSaving = false

    private var cost: Int { Tool.create.runCost }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                topBar

                Group {
                    switch vm.phase {
                    case .input: inputState
                    case .generating: generatingState
                    case .results: resultsState
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.phase)
        .overlay(alignment: .top) {
            if let message = vm.errorMessage {
                ErrorBanner(message: message) {
                    withAnimation { vm.errorMessage = nil }
                }
                .padding(.horizontal, 16)
                .padding(.top, 62)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.errorMessage)
        .preferredColorScheme(.dark)
        .runGate($gateRequest, onUpgrade: { showPaywall = true })
        .proPaywall(isPresented: $showPaywall)
        .toast($toast)
        .sheet(isPresented: $showShare) {
            if let shareURL { ShareSheet(items: [shareURL]) }
        }
        .alert("Photos access needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Clarity AI to add photos in Settings so results can be saved.")
        }
    }


    private var topBar: some View {
        HStack {
            IconButton(symbol: "xmark") {
                vm.cancel()
                dismiss()
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Create")
                    .font(.app(.headline, weight: .bold))
                    .foregroundColor(.white)
                if !subscription.isPro {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").font(.system(size: 9, weight: .bold))
                        Text("\(usage.remaining) free runs left")
                            .font(.app(.caption2, weight: .semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }


    private var inputState: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    promptSection
                    styleSection
                    countSection
                    strictnessSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)

            Button {
                generateTapped()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                    Text("Generate")
                    if !subscription.isPro {
                        Text("\(cost) runs")
                            .font(.app(.caption, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.22)))
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle(gradient: Theme.gradient(Theme.fuchsia, Theme.violet), glow: Theme.fuchsia))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PanelLabel(text: "Your idea")
                Button {
                    vm.surprise()
                } label: {
                    Label("Surprise me", systemImage: "dice.fill")
                        .font(.app(.footnote, weight: .semibold))
                        .foregroundColor(Theme.fuchsia)
                }
            }

            TextField("Describe the image you imagine…", text: $vm.prompt, axis: .vertical)
                .lineLimit(3...7)
                .font(.app(.body))
                .foregroundColor(Theme.textPrimary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )
                .onChange(of: vm.prompt) { text in
                    if text.count > 700 { vm.prompt = String(text.prefix(700)) }
                }

            if vm.prompt.trimmed.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.ideas.prefix(5), id: \.self) { idea in
                            Chip(title: idea, icon: "lightbulb.fill", selected: false) {
                                vm.prompt = idea
                            }
                        }
                    }
                }
            }
        }
    }

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelLabel(text: "Style")
            OptionRow(items: CreateStyle.allCases.map { OptionItem(title: $0.title, value: $0) },
                      selection: $vm.style)
        }
    }

    private var countSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelLabel(text: "Images per prompt")
            OptionRow(items: [
                OptionItem(title: "1", value: 1),
                OptionItem(title: "2", value: 2, locked: !subscription.isPro),
                OptionItem(title: "4", value: 4, locked: !subscription.isPro)
            ], selection: $vm.count, onLockedTap: { showPaywall = true })
        }
    }

    private var strictnessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelLabel(text: "Creativity")
            HStack(spacing: 12) {
                Text("Free")
                    .font(.app(.caption, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                Slider(value: $vm.strictness, in: 3...12, step: 1)
                    .tint(Theme.fuchsia)
                Text("Exact")
                    .font(.app(.caption, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
            Text("Lower values give the AI more freedom, higher values follow your words closely.")
                .font(.app(.caption))
                .foregroundColor(Theme.textTertiary)
        }
    }

    private func generateTapped() {
        hideKeyboard()
        if let problem = vm.validationMessage {
            vm.errorMessage = problem
            Haptics.warning()
            return
        }
        Haptics.medium()

        let isPro = subscription.isPro
        let charged = cost
        let start: () -> Void = {
            vm.generate(library: library, isPro: isPro, refund: {
                if !isPro { usage.refund(charged) }
            })
        }
        if isPro {
            start()
        } else {
            gateRequest = RunGateRequest(cost: charged, title: "Create", action: start)
        }
    }


    private var generatingState: some View {
        ProcessingView(image: nil, status: vm.statusText) {
            vm.cancel()
        }
    }


    private var resultsState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                TabView(selection: $vm.selectedIndex) {
                    ForEach(Array(vm.results.enumerated()), id: \.element.id) { index, generated in
                        Image(uiImage: generated.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(Theme.stroke, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: vm.results.count > 1 ? .automatic : .never))
                .frame(height: 400)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.mint)
                    Text(vm.results.count > 1 ? "\(vm.results.count) images saved to your Library" : "Saved to your Library")
                }
                .font(.app(.footnote, weight: .medium))
                .foregroundColor(Theme.textSecondary)

                HStack(spacing: 12) {
                    Button {
                        saveCurrent()
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text("Save")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isSaving)

                    Button {
                        shareCurrent()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 16)

                if !subscription.isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 6) {
                            ProBadge(compact: true)
                            Text("Exports include a small Clarity AI mark. Remove it with Pro")
                                .font(.app(.caption, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                VStack(alignment: .leading, spacing: 10) {
                    PanelLabel(text: "Make it even better")
                        .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([Tool.enhance, .background, .magic, .color, .resize]) { tool in
                                Chip(title: tool.shortTitle, icon: tool.symbol, selected: false) {
                                    openEditor(with: tool)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                Button {
                    withAnimation { vm.reset() }
                } label: {
                    Label("New prompt", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .padding(.top, 4)
        }
    }

    private var currentData: Data? {
        guard vm.results.indices.contains(vm.selectedIndex) else { return nil }
        return vm.results[vm.selectedIndex].data
    }

    private func openEditor(with tool: Tool) {
        guard let data = currentData else { return }
        router.openEditor(tool: tool, imageData: data)
    }

    private func saveCurrent() {
        guard let data = currentData, !isSaving else { return }
        isSaving = true
        let watermark = !subscription.isPro
        Task {
            let prepared = await Task.detached(priority: .userInitiated) { () -> Data in
                ExportService.prepared(data, watermark: watermark)
            }.value
            do {
                try await ExportService.saveToPhotos(prepared)
                toast = "Saved to Photos"
                Haptics.success()
            } catch ExportError.permissionDenied {
                showPermissionAlert = true
            } catch {
                vm.errorMessage = "Couldn't save the image. Please try again."
                Haptics.error()
            }
            isSaving = false
        }
    }

    private func shareCurrent() {
        guard let data = currentData else { return }
        let watermark = !subscription.isPro
        Task {
            let prepared = await Task.detached(priority: .userInitiated) { () -> Data in
                ExportService.prepared(data, watermark: watermark)
            }.value
            if let url = ExportService.temporaryFile(for: prepared) {
                shareURL = url
                showShare = true
            }
        }
    }
}
