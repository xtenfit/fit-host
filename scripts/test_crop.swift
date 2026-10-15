import Foundation
import CoreGraphics
import ImageIO

func cropImage(sourcePath: String, destPath: String, rect: CGRect) {
    let sourceURL = URL(fileURLWithPath: sourcePath) as CFURL
    guard let imageSource = CGImageSourceCreateWithURL(sourceURL, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("Failed to load \(sourcePath)")
        return
    }
    
    // CoreGraphics origin for cropping(to:) is top-left in iOS/macOS CGImage coordinates
    // Note: in CGImage.cropping(to:), the rect is in pixels with (0,0) at top-left
    guard let cropped = cgImage.cropping(to: rect) else {
        print("Failed to crop \(sourcePath) with rect \(rect)")
        return
    }
    
    let destURL = URL(fileURLWithPath: destPath) as CFURL
    let uti = destPath.hasSuffix(".jpg") || destPath.hasSuffix(".jpeg") ? "public.jpeg" as CFString : "public.png" as CFString
    guard let destination = CGImageDestinationCreateWithURL(destURL, uti, 1, nil) else {
        print("Failed to create destination \(destPath)")
        return
    }
    
    CGImageDestinationAddImage(destination, cropped, nil)
    CGImageDestinationFinalize(destination)
    print("Successfully saved cropped image: \(destPath) (\(cropped.width)x\(cropped.height))")
}

// Test runner and cyclist
// Neon Running and Cycling Duo is 1670 x 941
// Let's crop Runner (left) and Cyclist (right)
cropImage(sourcePath: "assets/Neon Running and Cycling Duo.png",
          destPath: "build/test_swift_runner.png",
          rect: CGRect(x: 0, y: 0, width: 850, height: 941))

cropImage(sourcePath: "assets/Neon Running and Cycling Duo.png",
          destPath: "build/test_swift_cyclist.png",
          rect: CGRect(x: 820, y: 0, width: 850, height: 941))
