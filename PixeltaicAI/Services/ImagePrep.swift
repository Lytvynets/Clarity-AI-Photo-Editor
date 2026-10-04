

import UIKit
import ImageIO
import Vision

enum ImagePrep {

    static func pixelSize(of data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        let orientation = (props[kCGImagePropertyOrientation] as? Int) ?? 1
        if orientation >= 5 && orientation <= 8 {
            return CGSize(width: height, height: width)
        }
        return CGSize(width: width, height: height)
    }

    static func uploadJPEG(from data: Data, maxSide: CGFloat, quality: CGFloat = 0.92) -> Data? {
        let longest: CGFloat
        if let size = pixelSize(of: data) {
            longest = max(size.width, size.height)
        } else {
            longest = maxSide
        }
        let target = max(16, min(maxSide, longest))
        guard let image = ImageIOHelper.downsampledImage(data: data, maxPixel: target) else { return nil }
        return image.flattenedIfNeeded().jpegData(compressionQuality: quality)
    }

    static func hasFaces(in image: UIImage) async -> Bool {
        guard let cg = image.cgImage else { return false }
        return await Task.detached(priority: .utility) { () -> Bool in
            let request = VNDetectFaceRectanglesRequest()
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            do {
                try handler.perform([request])
            } catch {
                return false
            }
            return !(request.results?.isEmpty ?? true)
        }.value
    }
}

extension UIImage {
    func flattenedIfNeeded() -> UIImage {
        guard let cg = cgImage else { return self }
        switch cg.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return self
        default:
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            format.opaque = true
            let size = CGSize(width: cg.width, height: cg.height)
            return UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                self.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
