

import SwiftUI

struct LibraryDetailView: View {

    let itemID: UUID

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var router: Router

    @State private var afterImage: UIImage?
    @State private var beforeImage: UIImage?
    @State private var toast: String?
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showPaywall = false
    @State private var showDeleteDialog = false
    @State private var showPermissionAlert = false
    @State private var isSaving = false
    @State private var errorText: String?

    private var item: LibraryItem? { library.item(with: itemID) }

    var body: some View {
        ZStack {
            AppBackground()

            if let item {
                VStack(spacing: 0) {
                    topBar(item)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            imageArea(item)
                            info(item)
                            actions(item)
                            editMore(item)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toast($toast)
        .task(id: itemID) { await loadImages() }
        .proPaywall(isPresented: $showPaywall)
        .sheet(isPresented: $showShare) {
            if let shareURL { ShareSheet(items: [shareURL]) }
        }
        .confirmationDialog("Delete this result?", isPresented: $showDeleteDialog, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item {
                    library.delete(item)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It will be removed from this device.")
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
        .alert("Something went wrong",
               isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } }),
               actions: { Button("OK", role: .cancel) {} },
               message: { Text(errorText ?? "") })
    }


    private func topBar(_ item: LibraryItem) -> some View {
        HStack {
            IconButton(symbol: "chevron.left") { dismiss() }
            Spacer()
            Text(item.tool?.title ?? "Result")
                .font(.app(.headline, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 8) {
                IconButton(symbol: item.isFavorite ? "heart.fill" : "heart",
                           tint: item.isFavorite ? Theme.pink : .white) {
                    library.toggleFavorite(item)
                }
                IconButton(symbol: "trash", tint: Theme.danger) {
                    showDeleteDialog = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func imageArea(_ item: LibraryItem) -> some View {
        if let after = afterImage {
            if item.hasBefore, let before = beforeImage {
                BeforeAfterSlider(before: before, after: after, transparent: item.isTransparent)
            } else {
                ImageCanvas(image: after, transparent: item.isTransparent)
            }
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .aspectRatio(1, contentMode: .fit)
                .shimmering()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func info(_ item: LibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.app(.headline, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(item.pixelWidth) × \(item.pixelHeight) · \(item.createdAt.libraryLabel)")
                .font(.app(.caption))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func actions(_ item: LibraryItem) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    save(item)
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
                    share(item)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

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
            }
        }
    }

    private func editMore(_ item: LibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelLabel(text: "Edit this again")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Tool.photoTools) { tool in
                        Chip(title: tool.shortTitle, icon: tool.symbol, selected: false) {
                            if let data = library.resultData(for: item) {
                                router.openEditor(tool: tool, imageData: data)
                            }
                        }
                    }
                }
            }
        }
    }


    private func loadImages() async {
        guard let item else { return }
        afterImage = await library.displayImage(for: item)
        if item.hasBefore {
            beforeImage = await library.displayImage(for: item, before: true)
        }
    }

    private func save(_ item: LibraryItem) {
        guard let data = library.resultData(for: item), !isSaving else { return }
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
                errorText = "Couldn't save the image. Please try again."
                Haptics.error()
            }
            isSaving = false
        }
    }

    private func share(_ item: LibraryItem) {
        guard let data = library.resultData(for: item) else { return }
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
