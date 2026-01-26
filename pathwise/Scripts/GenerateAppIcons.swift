import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// Local renderer view for the script to avoid colliding with the app's AppIconView
private struct IconRendererView: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.0, green: 0.5, blue: 1.0), Color(red: 0.0, green: 0.2, blue: 0.7)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            Text("🌀")
                .font(.system(size: 100))
        }
    }
}

// Wrap script logic in a function and call it at the end to avoid @main conflicts
@MainActor
private func generateIcons() {
    let root = FileManager.default.currentDirectoryPath
    let outputDir = URL(fileURLWithPath: root)
        .appendingPathComponent("Assets.xcassets")
        .appendingPathComponent("AppIcon.appiconset")

    let specs: [(String, CGFloat)] = [
        ("Icon-20@2x.png", 40),
        ("Icon-20@3x.png", 60),
        ("Icon-29@2x.png", 58),
        ("Icon-29@3x.png", 87),
        ("Icon-40@2x.png", 80),
        ("Icon-40@3x.png", 120),
        ("Icon-60@2x.png", 120),
        ("Icon-60@3x.png", 180),
        ("Icon-1024.png", 1024)
    ]

    do {
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    } catch {
        fputs("Failed to create output directory: \(error)\n", stderr)
        exit(1)
    }

    for (filename, size) in specs {
        #if canImport(AppKit)
        let view = IconRendererView()
            .frame(width: size, height: size)
            .ignoresSafeArea()

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        if let nsImage = renderer.nsImage {
            if let tiff = nsImage.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let data = bitmap.representation(using: .png, properties: [:]) {
                let url = outputDir.appendingPathComponent(filename)
                do {
                    try data.write(to: url)
                    print("Wrote: \(url.path)")
                } catch {
                    fputs("Failed writing \(filename): \(error)\n", stderr)
                }
            } else {
                fputs("Failed to create PNG data for \(filename)\n", stderr)
            }
        } else {
            fputs("Failed to render view for \(filename)\n", stderr)
        }
        #else
        fputs("This script must be run on macOS with AppKit available.\n", stderr)
        #endif
    }
}

// Kick off generation synchronously on the main actor
Task { @MainActor in
    generateIcons()
    exit(EXIT_SUCCESS)
}

// Keep the script running until the task exits
RunLoop.main.run()
