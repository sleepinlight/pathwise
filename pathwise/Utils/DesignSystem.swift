//
//  DesignSystem.swift
//  pathwise
//
//  Design system for Pathwise - colors, typography, and styling
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Original Brand Colors (Sage Green - commented out)
//    static let sageGreen = Color(hex: "#718355")
//    static let cream = Color(hex: "#F9F7F2")
//    static let slateBlue = Color(hex: "#4A5759")

    // BLUE OPTIONS

    // OPTION 1: Ocean Blue
    static let oceanBlue = Color(hex: "#5B8FA3")      // Medium ocean blue
    static let skyBlue = Color(hex: "#E5F2F7")        // Very light sky blue background
    static let paleOcean = Color(hex: "#F0F7FA")      // Pale blue-white for cards
    static let deepOcean = Color(hex: "#3A5A6B")      // Deep blue for text

    // OPTION 2: Soft Periwinkle
    static let periwinkle = Color(hex: "#7B90D2")     // Soft purple-blue
    static let lavenderMist = Color(hex: "#EEF1F9")   // Very light lavender background
    static let paleLavender = Color(hex: "#F5F7FC")   // Pale lavender for cards
    static let deepPeriwinkle = Color(hex: "#4A5A8D") // Deep blue-purple for text

    // OPTION 3: Steel Blue
//    static let steelBlue = Color(hex: "#6B8CAE")      // Cool steel blue
//    static let cloudGrey = Color(hex: "#E8ECF1")      // Light grey-blue background
//    static let paleSteel = Color(hex: "#F2F5F8")      // Very light steel for cards
//    static let deepSteel = Color(hex: "#3D4F5F")      // Deep grey-blue for text

    // ORANGE OPTIONS

    // OPTION 4: Sunset Orange
//    static let sunsetOrange = Color(hex: "#E8956C")   // Warm peachy-orange
//    static let sunsetCream = Color(hex: "#FFF5EF")    // Very light peachy background
//    static let paleSunset = Color(hex: "#FFF9F5")     // Pale peach for cards
//    static let deepBrown = Color(hex: "#5A4A42")      // Warm brown for text

    // OPTION 5: Amber & Cream
//    static let amber = Color(hex: "#D4915D")          // Golden amber
//    static let warmIvory = Color(hex: "#FFF8F0")      // Warm ivory background
//    static let paleAmber = Color(hex: "#FFFAF5")      // Very pale amber for cards
//    static let richBrown = Color(hex: "#4A3F35")      // Rich brown for text

    // OPTION 6: Coral Reef
//    static let coralOrange = Color(hex: "#E89A7B")    // Soft coral
//    static let sandyBeige = Color(hex: "#F9F3ED")     // Sandy beige background
//    static let paleCoral = Color(hex: "#FFF7F3")      // Very pale coral for cards
//    static let deepCoral = Color(hex: "#5D4A42")      // Deep warm brown for text

    // BLUE + ORANGE COMBO

    // OPTION 7: Blue Sky + Sunset
    static let skyBlueAccent = Color(hex: "#6B9FBD")  // Sky blue
    static let sunriseOrange = Color(hex: "#E8A87C")  // Sunrise orange (secondary accent)
    static let cloudWhite = Color(hex: "#F0F5F9")     // Cloud white background
    static let paleCloud = Color(hex: "#F8FBFD")      // Very pale blue for cards
    static let oceanText = Color(hex: "#3B5260")      // Deep blue-grey for text

    // Semantic Colors - OPTION 1: Ocean Blue (ACTIVE)
//    static let primaryBackground = Color.skyBlue
//    static let primaryText = Color.deepOcean
//    static let accent = Color.oceanBlue
//    static let cardBackground = Color.paleOcean

    // OPTION 2: Soft Periwinkle
//    static let primaryBackground = Color.lavenderMist
//    static let primaryText = Color.deepPeriwinkle
//    static let accent = Color.periwinkle
//    static let cardBackground = Color.paleLavender

    // OPTION 3: Steel Blue
//    static let primaryBackground = Color.cloudGrey
//    static let primaryText = Color.deepSteel
//    static let accent = Color.steelBlue
//    static let cardBackground = Color.paleSteel

    // OPTION 4: Sunset Orange
//    static let primaryBackground = Color.sunsetCream
//    static let primaryText = Color.deepBrown
//    static let accent = Color.sunsetOrange
//    static let cardBackground = Color.paleSunset

    // OPTION 5: Amber & Cream
//    static let primaryBackground = Color.warmIvory
//    static let primaryText = Color.richBrown
//    static let accent = Color.amber
//    static let cardBackground = Color.paleAmber

    // OPTION 6: Coral Reef
//    static let primaryBackground = Color.sandyBeige
//    static let primaryText = Color.deepCoral
//    static let accent = Color.coralOrange
//    static let cardBackground = Color.paleCoral

    // OPTION 7: Blue Sky + Sunset (two accent colors!)
    // Light Mode Colors
    static let lightBackground = Color.cloudWhite
    static let lightText = Color.oceanText
    static let lightCardBackground = Color.paleCloud

    // Dark Mode Colors - Default (Blue)
    static let darkBackground = Color(hex: "#0A1929")        // Deep blue-black
    static let darkBackgroundGradientTop = Color(hex: "#0D1F33") // Slightly lighter blue for gradient
    static let darkText = Color(hex: "#E3F2FD")              // Very light blue-white
    static let darkCardBackground = Color(hex: "#132F4C")     // Dark blue for cards

    // Dark Mode Colors - Black
    static let blackBackground = Color(hex: "#000000")        // Pure black
    static let blackText = Color(hex: "#FFFFFF")              // Pure white
    static let blackCardBackground = Color(hex: "#1C1C1E")    // Dark gray for cards

    // Semantic Colors - Adaptive based on color scheme and dark mode style
    static var primaryBackground: Color {
        adaptiveColor(light: lightBackground, darkDefault: darkBackground, darkBlack: blackBackground)
    }

    static var primaryText: Color {
        adaptiveColor(light: lightText, darkDefault: darkText, darkBlack: blackText)
    }

    static let accent = Color.skyBlueAccent  // Same in both modes

    static var cardBackground: Color {
        adaptiveColor(light: lightCardBackground, darkDefault: darkCardBackground, darkBlack: blackCardBackground)
    }

    // Helper for adaptive colors based on dark mode style
    private static func adaptiveColor(light: Color, darkDefault: Color, darkBlack: Color) -> Color {
        Color(adaptiveDynamic: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Check user preference for dark mode style
                if let data = UserDefaults.standard.data(forKey: "userPreferences"),
                   let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data),
                   preferences.darkModeStyle == .black {
                    return UIColor(darkBlack)
                }
                return UIColor(darkDefault)
            }
            return UIColor(light)
        })
    }

    // Secondary accent
    static let secondaryAccent = Color.sunriseOrange  // Use for warm highlights
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

    // Adaptive color initializer for light/dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }

    // Adaptive color initializer with custom dynamic logic
    init(adaptiveDynamic: @escaping (UITraitCollection) -> UIColor) {
        self.init(uiColor: UIColor(dynamicProvider: adaptiveDynamic))
    }
}
