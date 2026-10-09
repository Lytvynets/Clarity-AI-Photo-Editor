

import SwiftUI
import PhotosUI

struct EditorView: View {

    let request: EditorRequest

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var usage: UsageManager
    @EnvironmentObject private var library: LibraryStore

    @StateObject private var vm: EditorViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var gateRequest: RunGateRequest?
    @State private var showPaywall = false
    @State private var paywallPlacement = "editor"
    @State private var toast: String?
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showPermissionAlert = false
    @State private var isSaving = false
    @State private var floating = false

    init(request: EditorRequest) {
        self.request = request
        _vm = StateObject(wrappedValue: EditorViewModel(tool: request.tool))
    }


    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                topBar

                Group {
                    switch vm.phase {
                    case .empty: emptyState
                    case .ready: readyState
                    case .processing: processingState
                    case .result: resultState
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
        .runGate($gateRequest, onUpgrade: { openPaywall("run_gate") })
        .proPaywall(isPresented: $showPaywall, placement: paywallPlacement)
        .toast($toast)
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        .alert("Photos access needed", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow Clarity AI to add photos in Settings so results can be saved to your library.")
        }
        .onAppear {
            vm.isPro = subscription.isPro
            AppAnalytics.log(AppAnalytics.Event.toolOpen,
                             ["tool": request.tool.id, "has_photo": request.imageData == nil ? 0 : 1])
            if let data = request.imageData, vm.originalData == nil {
                vm.setPhoto(data: data)
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { floating = true }
        }
        .onChange(of: subscription.isPro) { value in
            vm.isPro = value
        }
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            Task {
                await vm.loadPhoto(from: item)
                pickerItem = nil
            }
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
                Text(vm.tool.title)
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

            if vm.phase == .ready {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                        .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
                }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }


    private var emptyState: some View {
        VStack(spacing: 26) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 210, height: 210)

                GradientTile(symbol: vm.tool.symbol, colors: vm.tool.colors, size: 96)
                    .offset(y: floating ? -8 : 8)

                if vm.isLoadingPhoto {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                        .frame(width: 210, height: 210)
                        .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Color.black.opacity(0.45)))
                }
            }

            VStack(spacing: 8) {
                Text(vm.tool.subtitle)
                    .font(.app(.title3, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(vm.tool.pickerHint)
                    .font(.app(.subheadline))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                        Text("Choose photo")
                    }
                    .font(.app(.headline, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.brandGradient))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: Theme.violet.opacity(0.45), radius: 18, x: 0, y: 8)
                }

                if UIPasteboard.general.hasImages {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func pasteFromClipboard() {
        guard let image = UIPasteboard.general.image,
              let data = image.jpegData(compressionQuality: 0.95) else {
            vm.errorMessage = "There's no image on the clipboard."
            return
        }
        vm.setPhoto(data: data)
    }


    private var readyState: some View {
        GeometryReader { geo in
            VStack(spacing: 12) {
                if let image = vm.originalImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Theme.stroke, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                toolSwitcher

                ScrollView(showsIndicators: false) {
                    ToolPanel(vm: vm, isPro: subscription.isPro, onLocked: { openPaywall("editor_locked") })
                        .padding(16)
                }
                .frame(height: min(geo.size.height * 0.40, 330))
                .glassCard(radius: 24)
                .padding(.horizontal, 16)
                .dismissKeyboardOnTap()

                runButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    private var toolSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tool.photoTools) { item in
                    Chip(title: item.shortTitle, icon: item.symbol, selected: vm.tool == item) {
                        withAnimation(.easeInOut(duration: 0.2)) { vm.tool = item }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var runButton: some View {
        Button {
            tapRun()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                Text(vm.actionTitle)
                if !subscription.isPro {
                    Text(vm.runCost == 1 ? "1 run" : "\(vm.runCost) runs")
                        .font(.app(.caption, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.22)))
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    private func tapRun() {
        hideKeyboard()
        if let problem = vm.validationMessage {
            vm.errorMessage = problem
            Haptics.warning()
            return
        }
        Haptics.medium()

        let cost = vm.runCost
        let isPro = subscription.isPro
        let start: () -> Void = {
            vm.run(library: library, isPro: isPro, refund: {
                if isPro { usage.proRefund(cost) } else { usage.refund(cost) }
            })
        }

        if isPro {
            // Subscribers are not metered per tool, but every AI call costs real money, so there is
            // a generous daily fair-use cap (smaller during the free trial).
            let limit = subscription.proDailyLimit
            guard usage.proCanAfford(cost, limit: limit) else {
                vm.errorMessage = "You've reached today's Pro limit. \(usage.resetText)."
                Haptics.warning()
                AppAnalytics.log(AppAnalytics.Event.proLimitReached, ["tool": vm.tool.id, "limit": limit])
                return
            }
            usage.proConsume(cost)
            start()
        } else {
            gateRequest = RunGateRequest(cost: cost, title: vm.tool.title, tool: vm.tool.id, action: start)
        }
    }

    private func openPaywall(_ placement: String) {
        paywallPlacement = placement
        showPaywall = true
    }


    private var processingState: some View {
        ProcessingView(image: vm.originalImage, status: vm.statusText) {
            vm.cancel()
        }
    }


    private var resultState: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                if let before = vm.originalImage, let after = vm.resultImage {
                    BeforeAfterSlider(before: before, after: after, transparent: vm.resultIsTransparent, verticalScrollFriendly: true)
                        .padding(.horizontal, 16)
                }

                HStack(spacing: 6) {
                    if vm.savedItem != nil {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.mint)
                        Text("Saved to your Library")
                    } else {
                        ProgressView().scaleEffect(0.7).tint(.white)
                        Text("Saving to Library…")
                    }
                }
                .font(.app(.footnote, weight: .medium))
                .foregroundColor(Theme.textSecondary)

                HStack(spacing: 12) {
                    Button {
                        saveToPhotos()
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
                        share()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 16)

                if !subscription.isPro {
                    Button {
                        openPaywall("editor_watermark")
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
                    PanelLabel(text: "Keep editing this result")
                        .padding(.horizontal, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Tool.photoTools.filter { $0 != vm.tool }) { item in
                                Chip(title: item.shortTitle, icon: item.symbol, selected: false) {
                                    withAnimation { vm.continueEditing(with: item) }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        withAnimation { vm.backToReady() }
                    } label: {
                        Label("Adjust & redo", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        withAnimation { vm.startOver() }
                    } label: {
                        Label("New photo", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .padding(.top, 4)
        }
    }


    private func saveToPhotos() {
        guard let data = vm.resultData, !isSaving else { return }
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
                AppAnalytics.log(AppAnalytics.Event.resultSave, ["tool": vm.tool.id, "watermark": watermark ? 1 : 0])
            } catch ExportError.permissionDenied {
                showPermissionAlert = true
            } catch {
                vm.errorMessage = "Couldn't save the image. Please try again."
                Haptics.error()
            }
            isSaving = false
        }
    }

    private func share() {
        guard let data = vm.resultData else { return }
        let watermark = !subscription.isPro
        Task {
            let prepared = await Task.detached(priority: .userInitiated) { () -> Data in
                ExportService.prepared(data, watermark: watermark)
            }.value
            if let url = ExportService.temporaryFile(for: prepared) {
                shareURL = url
                showShare = true
                AppAnalytics.log(AppAnalytics.Event.resultShare, ["tool": vm.tool.id, "watermark": watermark ? 1 : 0])
            }
        }
    }
}
