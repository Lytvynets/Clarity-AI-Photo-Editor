

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case studio, library, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .studio: return "Studio"
        case .library: return "Library"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .studio: return "sparkles"
        case .library: return "square.grid.2x2.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct EditorRequest {
    let tool: Tool
    let imageData: Data?
}

enum AppDestination: Identifiable {
    case editor(id: UUID, request: EditorRequest)
    case create(id: UUID)

    var id: UUID {
        switch self {
        case .editor(let id, _): return id
        case .create(let id): return id
        }
    }
}

@MainActor
final class Router: ObservableObject {
    @Published var tab: AppTab = .studio
    @Published var destination: AppDestination?
    /// Top edge (screen coordinates) of the banner + tab bar strip at the bottom of the main
    /// screen. 0 until measured. Pushed pages use it to keep their last buttons above the bar.
    @Published var bottomBarMinY: CGFloat = 0

    func openEditor(tool: Tool, imageData: Data? = nil) {
        destination = .editor(id: UUID(), request: EditorRequest(tool: tool, imageData: imageData))
    }

    func openCreate() {
        destination = .create(id: UUID())
    }

    func closeDestination() {
        destination = nil
    }
}
