

import SwiftUI

struct LibraryThumbnail: View {
    let item: LibraryItem
    @EnvironmentObject private var library: LibraryStore
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if item.isTransparent {
                CheckerboardView()
            } else {
                Color.white.opacity(0.06)
            }
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Color.clear.shimmering()
            }
        }
        .clipped()
        .task(id: item.id) {
            image = await library.thumbnail(for: item)
        }
        .animation(.easeOut(duration: 0.25), value: image != nil)
    }
}

struct LibraryView: View {

    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var router: Router

    private enum Filter: String, CaseIterable, Identifiable {
        case all, favorites
        var id: String { rawValue }
        var title: String { self == .all ? "All" : "Favorites" }
    }

    @State private var filter: Filter = .all
    @State private var path: [UUID] = []

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var visibleItems: [LibraryItem] {
        filter == .all ? library.items : library.items.filter { $0.isFavorite }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppBackground()

                VStack(alignment: .leading, spacing: 0) {
                    header

                    if library.items.isEmpty {
                        emptyState
                    } else if visibleItems.isEmpty {
                        noFavorites
                    } else {
                        grid
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                LibraryDetailView(itemID: id)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }


    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Library")
                    .font(.app(.largeTitle, weight: .heavy))
                    .foregroundColor(.white)
                Text(library.items.isEmpty ? "Your creations live here" : "\(library.items.count) saved on this device")
                    .font(.app(.subheadline))
                    .foregroundColor(Theme.textSecondary)
            }

            if !library.items.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Filter.allCases) { item in
                        Chip(title: item.title,
                             icon: item == .favorites ? "heart.fill" : nil,
                             selected: filter == item) {
                            withAnimation(.easeInOut(duration: 0.2)) { filter = item }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private var grid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(visibleItems) { item in
                    NavigationLink(value: item.id) {
                        cell(item)
                    }
                    .buttonStyle(PressableStyle())
                    .contextMenu {
                        Button {
                            library.toggleFavorite(item)
                        } label: {
                            Label(item.isFavorite ? "Remove from favorites" : "Add to favorites",
                                  systemImage: item.isFavorite ? "heart.slash" : "heart")
                        }
                        Button(role: .destructive) {
                            library.delete(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func cell(_ item: LibraryItem) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(LibraryThumbnail(item: item))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.pink)
                        .padding(7)
                        .background(Circle().fill(Color.black.opacity(0.45)))
                        .padding(8)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let tool = item.tool {
                    HStack(spacing: 5) {
                        Image(systemName: tool.symbol).font(.system(size: 10, weight: .bold))
                        Text(tool.shortTitle).font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    .padding(8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            GradientTile(symbol: "photo.on.rectangle.angled", colors: [Theme.violet, Theme.fuchsia], size: 84)
            VStack(spacing: 6) {
                Text("Nothing here yet")
                    .font(.app(.title3, weight: .bold))
                    .foregroundColor(.white)
                Text("Everything you edit or create is saved here automatically.")
                    .font(.app(.subheadline))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                router.tab = .studio
            } label: {
                Text("Open Studio")
            }
            .buttonStyle(PrimaryButtonStyle())
            .frame(width: 200)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }

    private var noFavorites: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "heart")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
            Text("No favorites yet")
                .font(.app(.headline, weight: .bold))
                .foregroundColor(.white)
            Text("Open a result and tap the heart to pin it here.")
                .font(.app(.subheadline))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
