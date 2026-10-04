

import Foundation
import UIKit

struct LibraryItem: Codable, Identifiable, Equatable {
    var id: UUID
    var createdAt: Date
    var toolID: String
    var title: String
    var fileExtension: String
    var hasBefore: Bool
    var isTransparent: Bool
    var pixelWidth: Int
    var pixelHeight: Int
    var prompt: String?
    var isFavorite: Bool

    var tool: Tool? { Tool(rawValue: toolID) }
}

@MainActor
final class LibraryStore: ObservableObject {

    @Published private(set) var items: [LibraryItem] = []

    private let directory: URL
    private let indexURL: URL
    private let thumbnailCache = NSCache<NSString, UIImage>()

    init() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("Library", isDirectory: true)
        indexURL = directory.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        thumbnailCache.countLimit = 150
        load()
    }


    func resultURL(_ item: LibraryItem) -> URL {
        directory.appendingPathComponent("\(item.id.uuidString).\(item.fileExtension)")
    }

    func beforeURL(_ item: LibraryItem) -> URL {
        directory.appendingPathComponent("\(item.id.uuidString)_before.jpg")
    }

    func thumbnailURL(_ item: LibraryItem) -> URL {
        directory.appendingPathComponent("\(item.id.uuidString)_thumb.\(item.fileExtension)")
    }

    func item(with id: UUID) -> LibraryItem? {
        items.first { $0.id == id }
    }


    @discardableResult
    func add(resultData: Data,
             before: UIImage?,
             tool: Tool,
             title: String,
             prompt: String? = nil,
             isTransparent: Bool = false) async -> LibraryItem? {

        let id = UUID()
        let isPNG = resultData.isPNG
        let fileExtension = isPNG ? "png" : "jpg"
        let beforeData = before?.jpegData(compressionQuality: 0.85)
        let directory = self.directory

        let written = await Task.detached(priority: .utility) { () -> WriteResult? in
            LibraryStore.writeFiles(id: id,
                                    fileExtension: fileExtension,
                                    isPNG: isPNG,
                                    resultData: resultData,
                                    beforeData: beforeData,
                                    directory: directory)
        }.value

        guard let written else { return nil }

        let item = LibraryItem(id: id,
                               createdAt: Date(),
                               toolID: tool.rawValue,
                               title: title,
                               fileExtension: fileExtension,
                               hasBefore: beforeData != nil,
                               isTransparent: isTransparent && isPNG,
                               pixelWidth: written.width,
                               pixelHeight: written.height,
                               prompt: prompt,
                               isFavorite: false)
        items.insert(item, at: 0)
        saveIndex()
        return item
    }

    private struct WriteResult {
        let width: Int
        let height: Int
    }

    nonisolated private static func writeFiles(id: UUID,
                                               fileExtension: String,
                                               isPNG: Bool,
                                               resultData: Data,
                                               beforeData: Data?,
                                               directory: URL) -> WriteResult? {
        let name = id.uuidString
        do {
            try resultData.write(to: directory.appendingPathComponent("\(name).\(fileExtension)"), options: .atomic)
            if let beforeData {
                try beforeData.write(to: directory.appendingPathComponent("\(name)_before.jpg"), options: .atomic)
            }
        } catch {
            print("⚠️ Could not write result: \(error)")
            return nil
        }

        if let thumb = ImageIOHelper.downsampledImage(data: resultData, maxPixel: 700) {
            let thumbData = isPNG ? thumb.pngData() : thumb.jpegData(compressionQuality: 0.8)
            try? thumbData?.write(to: directory.appendingPathComponent("\(name)_thumb.\(fileExtension)"), options: .atomic)
        }

        let size = ImagePrep.pixelSize(of: resultData) ?? CGSize(width: 1024, height: 1024)
        return WriteResult(width: Int(size.width), height: Int(size.height))
    }


    func thumbnail(for item: LibraryItem) async -> UIImage? {
        let key = item.id.uuidString as NSString
        if let cached = thumbnailCache.object(forKey: key) { return cached }

        let thumbPath = thumbnailURL(item).path
        let fullPath = resultURL(item).path
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            if let thumb = UIImage(contentsOfFile: thumbPath) { return thumb }
            return ImageIOHelper.downsampledImage(at: URL(fileURLWithPath: fullPath), maxPixel: 700)
        }.value

        if let image { thumbnailCache.setObject(image, forKey: key) }
        return image
    }

    func displayImage(for item: LibraryItem, before: Bool = false) async -> UIImage? {
        let url = before ? beforeURL(item) : resultURL(item)
        return await Task.detached(priority: .userInitiated) { () -> UIImage? in
            ImageIOHelper.downsampledImage(at: url, maxPixel: 2400)
        }.value
    }

    func resultData(for item: LibraryItem) -> Data? {
        try? Data(contentsOf: resultURL(item))
    }


    func toggleFavorite(_ item: LibraryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isFavorite.toggle()
        saveIndex()
    }

    func delete(_ item: LibraryItem) {
        remove(files(for: item))
        items.removeAll { $0.id == item.id }
        thumbnailCache.removeObject(forKey: item.id.uuidString as NSString)
        saveIndex()
    }

    func deleteAll() {
        for item in items { remove(files(for: item)) }
        items.removeAll()
        thumbnailCache.removeAllObjects()
        saveIndex()
    }

    private func files(for item: LibraryItem) -> [URL] {
        [resultURL(item), beforeURL(item), thumbnailURL(item)]
    }

    private func remove(_ urls: [URL]) {
        for url in urls { try? FileManager.default.removeItem(at: url) }
    }


    private func saveIndex() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(items)
            try data.write(to: indexURL, options: .atomic)
        } catch {
            print("⚠️ Could not save library index: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([LibraryItem].self, from: data) else { return }
        items = decoded.filter { FileManager.default.fileExists(atPath: resultURL($0).path) }
    }
}
