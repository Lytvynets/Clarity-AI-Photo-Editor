

import UIKit
import ImageIO

extension Data {
    var isPNG: Bool {
        count >= 4 && self[startIndex] == 0x89 && self[startIndex + 1] == 0x50
            && self[startIndex + 2] == 0x4E && self[startIndex + 3] == 0x47
    }
}

extension UIImage {

    var pixelSize: CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }


    func normalized(maxSide: CGFloat) -> UIImage {
        let px = pixelSize
        let longest = max(px.width, px.height)
        guard longest > 0 else { return self }
        let ratio = longest > maxSide ? maxSide / longest : 1
        if imageOrientation == .up && ratio == 1 && scale == 1 { return self }

        let target = CGSize(width: max(1, (px.width * ratio).rounded(.down)),
                            height: max(1, (px.height * ratio).rounded(.down)))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    func uploadJPEG(quality: CGFloat = 0.92) -> Data? {
        jpegData(compressionQuality: quality)
    }

    func watermarked(text: String) -> UIImage {
        let px = pixelSize
        guard px.width > 0, px.height > 0 else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: px, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: px))

            let fontSize = max(13, min(px.width, px.height) * 0.034)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            let label = NSAttributedString(string: "✦ " + text, attributes: attributes)
            let textSize = label.size()
            let padX = fontSize * 0.75
            let padY = fontSize * 0.45
            let margin = fontSize * 0.9
            let pill = CGRect(x: px.width - textSize.width - padX * 2 - margin,
                              y: px.height - textSize.height - padY * 2 - margin,
                              width: textSize.width + padX * 2,
                              height: textSize.height + padY * 2)
            UIColor.black.withAlphaComponent(0.42).setFill()
            UIBezierPath(roundedRect: pill, cornerRadius: pill.height / 2).fill()
            label.draw(at: CGPoint(x: pill.minX + padX, y: pill.minY + padY))
        }
    }

    var looksCompletelyBlack: Bool {
        guard let cg = cgImage else { return false }
        let w = 16, h = 16
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let ctx = CGContext(data: buffer.baseAddress,
                                      width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return false }
        var total = 0
        var index = 0
        while index < pixels.count {
            total += Int(pixels[index]) + Int(pixels[index + 1]) + Int(pixels[index + 2])
            index += 4
        }
        let average = Double(total) / Double(w * h * 3)
        return average < 3.0
    }
}

enum ImageIOHelper {
    static func downsampledImage(at url: URL, maxPixel: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cg)
    }

    static func downsampledImage(data: Data, maxPixel: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cg)
    }
}
