import Foundation
import CoreGraphics
import ImageIO

func removeWhiteBackground(sourcePath: String, destPath: String, threshold: UInt8 = 242) {
    let sourceURL = URL(fileURLWithPath: sourcePath) as CFURL
    guard let imageSource = CGImageSourceCreateWithURL(sourceURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("Failed to load \(sourcePath)")
        return
    }
    
    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let bitsPerComponent = 8
    
    var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)
    guard let context = CGContext(
        data: &rawData,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    ) else {
        print("Failed to create CGContext")
        return
    }
    
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    
    // Pixel format: R, G, B, A
    let thresh = Int(threshold)
    for i in stride(from: 0, to: rawData.count, by: 4) {
        let r = Int(rawData[i])
        let g = Int(rawData[i + 1])
        let b = Int(rawData[i + 2])
        let a = Int(rawData[i + 3])
        
        if r >= thresh && g >= thresh && b >= thresh {
            let avg = (r + g + b) / 3
            if avg >= 252 {
                rawData[i] = 0
                rawData[i + 1] = 0
                rawData[i + 2] = 0
                rawData[i + 3] = 0
            } else {
                let factor = Double(255 - avg) / Double(255 - thresh)
                let newA = UInt8(clamping: Int(Double(a) * factor))
                rawData[i] = UInt8(clamping: Int(Double(r) * factor))
                rawData[i + 1] = UInt8(clamping: Int(Double(g) * factor))
                rawData[i + 2] = UInt8(clamping: Int(Double(b) * factor))
                rawData[i + 3] = newA
            }
        }
    }
    
    guard let newCgImage = context.makeImage() else {
        print("Failed to create new CGImage")
        return
    }
    
    let destURL = URL(fileURLWithPath: destPath) as CFURL
    guard let destination = CGImageDestinationCreateWithURL(destURL, "public.png" as CFString, 1, nil) else {
        print("Failed to create destination")
        return
    }
    
    CGImageDestinationAddImage(destination, newCgImage, nil)
    CGImageDestinationFinalize(destination)
    print("Successfully processed transparent image: \(destPath) (\(width)x\(height))")
}

let args = CommandLine.arguments
if args.count >= 3 {
    removeWhiteBackground(sourcePath: args[1], destPath: args[2])
} else {
    removeWhiteBackground(sourcePath: "assets/images/nutrition/hydration.png", destPath: "assets/images/nutrition/hydration.png")
}
