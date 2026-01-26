import SwiftUI

struct AppIconView: View {
    // Colors are pulled from the app's color system if available; otherwise fallback.
    var background: Color = Color.primaryBackground
    var accent: Color = Color.accent
    var sun: Color = Color.accent.opacity(0.9)
    var pathColor: Color = Color.primaryText.opacity(0.9)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                // Background rounded rect to match iOS icon squircle feel
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(background)

                // Subtle gradient overlay using accent tint to bring brand color
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.22), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Minimal sun
                Circle()
                    .fill(sun)
                    .frame(width: size * 0.22, height: size * 0.22)
                    .offset(x: size * 0.22, y: -size * 0.22)
                    .blur(radius: size * 0.01)

                // Walking path: a flowing S-curve ribbon
                Path { p in
                    let w = size
                    let h = size
                    let start = CGPoint(x: w * 0.1, y: h * 0.75)
                    let c1 = CGPoint(x: w * 0.35, y: h * 0.55)
                    let c2 = CGPoint(x: w * 0.55, y: h * 0.95)
                    let mid = CGPoint(x: w * 0.65, y: h * 0.70)
                    let c3 = CGPoint(x: w * 0.78, y: h * 0.55)
                    let c4 = CGPoint(x: w * 0.60, y: h * 0.35)
                    let end = CGPoint(x: w * 0.90, y: h * 0.30)

                    p.move(to: start)
                    p.addCurve(to: mid, control1: c1, control2: c2)
                    p.addCurve(to: end, control1: c3, control2: c4)
                }
                .stroke(pathColor, style: StrokeStyle(lineWidth: size * 0.10, lineCap: .round, lineJoin: .round))
                .shadow(color: pathColor.opacity(0.25), radius: size * 0.04, x: 0, y: size * 0.02)

                // Thin highlight edge to add depth
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: size * 0.02)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup()
    }
}

#Preview("App Icon Small") {
    AppIconView()
        .frame(width: 120, height: 120)
        .padding()
        .background(Color(.systemBackground))
}

#Preview("App Icon Large") {
    AppIconView()
        .frame(width: 512, height: 512)
        .padding()
        .background(Color(.systemBackground))
}

// Helper view to export quickly if desired
struct AppIconExportView: View {
    var body: some View {
        VStack(spacing: 24) {
            AppIconView()
                .frame(width: 1024, height: 1024)
            Text("Right-click the preview and choose Export to save a PNG.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview("Export 1024") {
    AppIconExportView()
}
