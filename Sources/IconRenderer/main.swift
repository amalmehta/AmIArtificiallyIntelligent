// Draws the app icon at 1024×1024 and writes the PNG sizes an .iconset needs.
// Usage: swift run IconRenderer <iconset-dir>   (scripts/make-icon.sh turns it into Resources/AppIcon.icns)
import SwiftUI
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

/// Human green on one side, machine magenta on the other, a head that is half brain and half chip, and a question mark.
struct AppIcon: View {
    let human = Color(hue: 0.40, saturation: 0.70, brightness: 0.80)
    let machine = Color(hue: 0.80, saturation: 0.72, brightness: 0.82)
    let ink = Color(hue: 0.68, saturation: 0.55, brightness: 0.22)

    var body: some View {
        ZStack {
            // macOS icon grid: 824pt rounded square centred on a 1024 canvas.
            RoundedRectangle(cornerRadius: 185, style: .continuous)
                .fill(machine)
                .overlay(
                    // Human half on the left, machine half on the right.
                    HStack(spacing: 0) {
                        LinearGradient(colors: [human, Color(hue: 0.44, saturation: 0.75, brightness: 0.66)], startPoint: .top, endPoint: .bottom)
                        LinearGradient(colors: [machine, Color(hue: 0.76, saturation: 0.75, brightness: 0.62)], startPoint: .top, endPoint: .bottom)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 185, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 185, style: .continuous)
                        .fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .top, endPoint: .center))
                )
                .frame(width: 824, height: 824)
                .shadow(color: .black.opacity(0.28), radius: 18, y: 10)

            ZStack {
                // Left half: the human brain.
                Image(systemName: "brain.head.profile")
                    .resizable().scaledToFit()
                    .foregroundStyle(.white)
                    .mask(HStack(spacing: 0) { Rectangle(); Color.clear })
                // Right half: the chip.
                Image(systemName: "cpu")
                    .resizable().scaledToFit()
                    .padding(28)
                    .foregroundStyle(.white)
                    .mask(HStack(spacing: 0) { Color.clear; Rectangle() })
            }
            .frame(width: 520, height: 520)
            .offset(y: -10)
            .shadow(color: .black.opacity(0.18), radius: 8, y: 6)

            // Divider between the halves.
            Capsule()
                .fill(.white.opacity(0.95))
                .frame(width: 8, height: 824)

            // Question-mark badge.
            ZStack {
                Circle().fill(.white)
                Text("?")
                    .font(.system(size: 150, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                    .offset(y: -4)
            }
            .frame(width: 200, height: 200)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
            .offset(x: 250, y: 250)
        }
        .frame(width: 1024, height: 1024)
    }
}

try MainActor.assumeIsolated {
    // iconset name → pixel size
    let sizes: [(String, Int)] = [
        ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
        ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
        ("icon_512x512", 512), ("icon_512x512@2x", 1024),
    ]
    for (name, px) in sizes {
        let renderer = ImageRenderer(content: AppIcon().environment(\.colorScheme, .light))
        renderer.scale = CGFloat(px) / 1024
        renderer.isOpaque = false
        guard let cg = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else {
            throw NSError(domain: "IconRenderer", code: 1, userInfo: [NSLocalizedDescriptionKey: "render failed: \(name)"])
        }
        try png.write(to: outDir.appendingPathComponent("\(name).png"))
    }
    print("wrote \(sizes.count) PNGs to \(outDir.path)")
}
