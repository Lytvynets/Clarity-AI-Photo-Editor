

import Foundation
import Photos
import UIKit

enum ExportError: LocalizedError {
    case permissionDenied
    case failed

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Allow Photos access in Settings to save images."
        case .failed: return "Couldn't save the image. Please try again."
        }
    }
}

enum ExportService {

    static func prepared(_ data: Data, watermark: Bool) -> Data {
        guard watermark, FreeTier.watermarkEnabled, let image = UIImage(data: data) else { return data }
        let marked = image.watermarked(text: FreeTier.watermarkText)
        if data.isPNG, let png = marked.pngData() { return png }
        return marked.jpegData(compressionQuality: 0.95) ?? data
    }

    static func saveToPhotos(_ data: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError.permissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }
        } catch {
            throw ExportError.failed
        }
    }

    static func temporaryFile(for data: Data, name: String = "Clarity") -> URL? {
        let ext = data.isPNG ? "png" : "jpg"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(Int(Date().timeIntervalSince1970)).\(ext)")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
