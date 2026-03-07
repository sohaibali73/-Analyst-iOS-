import SwiftUI

extension Color {
    // MARK: - Brand Colors
    
    static let potomacYellow = Color(hex: "FEC00F")
    static let potomacYellowLight = Color(hex: "FFD740")
    static let potomacYellowDark = Color(hex: "E5AD00")
    
    static let potomacGray = Color(hex: "212121")
    static let potomacGrayLight = Color(hex: "2E2E2E")
    
    static let potomacTurquoise = Color(hex: "00DED1")
    static let potomacPink = Color(hex: "EB2F5C")
    
    // MARK: - Semantic Colors (Adaptive)
    
    static let surfacePrimary = Color(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "121212")
    )
    
    static let surfaceSecondary = Color(
        light: Color(hex: "F8F9FA"),
        dark: Color(hex: "1E1E1E")
    )
    
    static let surfaceTertiary = Color(
        light: Color(hex: "F0F0F0"),
        dark: Color(hex: "262626")
    )
    
    static let surfaceInput = Color(
        light: Color(hex: "F8F8F8"),
        dark: Color(hex: "262626")
    )
    
    static let borderDefault = Color(
        light: Color(hex: "E5E5E5"),
        dark: Color(hex: "2E2E2E")
    )
    
    static let borderStrong = Color(
        light: Color(hex: "CCCCCC"),
        dark: Color(hex: "444444")
    )
    
    static let textPrimary = Color(
        light: Color(hex: "1A1A1A"),
        dark: Color(hex: "E8E8E8")
    )
    
    static let textSecondary = Color(
        light: Color(hex: "555555"),
        dark: Color(hex: "9E9E9E")
    )
    
    static let textMuted = Color(
        light: Color(hex: "888888"),
        dark: Color(hex: "757575")
    )
    
    // MARK: - Status Colors
    
    static let success = Color(hex: "22C55E")
    static let successLight = Color(hex: "22C55E").opacity(0.15)
    
    static let warning = Color(hex: "FEC00F")
    static let warningLight = Color(hex: "FEC00F").opacity(0.15)
    
    static let error = Color(hex: "DC2626")
    static let errorLight = Color(hex: "DC2626").opacity(0.15)
    
    static let info = Color(hex: "3B82F6")
    static let infoLight = Color(hex: "3B82F6").opacity(0.15)
    
    // MARK: - Chart Colors
    
    static let chartGreen = Color(hex: "22C55E")
    static let chartRed = Color(hex: "DC2626")
    static let chartBlue = Color(hex: "3B82F6")
    static let chartPurple = Color(hex: "8B5CF6")
    static let chartOrange = Color(hex: "F97316")
    static let chartPink = Color(hex: "EC4899")
    static let chartTurquoise = Color(hex: "00DED1")  // Same as potomacTurquoise
    
    // MARK: - Chat/UI Colors
    
    static let backgroundPrimary = Color(hex: "0A0A0A")
    static let cardBackground = Color.white.opacity(0.06)
    static let accentYellow = Color(hex: "F59E0B")
    static let accentGreen = Color(hex: "10B981")
    static let textTertiary = Color.white.opacity(0.4)
    static let borderPrimary = Color.white.opacity(0.1)
}

// MARK: - Color Initializers

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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        #if os(iOS) || os(visionOS)
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #elseif os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}