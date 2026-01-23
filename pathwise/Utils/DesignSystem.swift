//
//  DesignSystem.swift
//  pathwise
//
//  Design system for Pathwise - colors, typography, and styling
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Brand Colors
    static let sageGreen = Color(hex: "#718355")
    static let cream = Color(hex: "#F9F7F2")
    static let slateBlue = Color(hex: "#4A5759")

    // Semantic Colors
    static let primaryBackground = Color.cream
    static let primaryText = Color.slateBlue
    static let accent = Color.sageGreen
    static let cardBackground = Color.white
}

// MARK: - Typography
extension Font {
    static let pathwiseTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let pathwiseHeadline = Font.system(.title2, design: .rounded, weight: .semibold)
    static let pathwiseSubheadline = Font.system(.headline, design: .rounded, weight: .medium)
    static let pathwiseBody = Font.system(.body, design: .rounded, weight: .regular)
    static let pathwiseCaption = Font.system(.caption, design: .rounded, weight: .regular)
    static let pathwiseLargeNumber = Font.system(size: 48, weight: .bold, design: .rounded)
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Shadow Styles
extension View {
    func pathwiseCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    func pathwiseLightShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Color Helper (Hex)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
