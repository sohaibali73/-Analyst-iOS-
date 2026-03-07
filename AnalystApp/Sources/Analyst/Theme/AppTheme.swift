import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Codable {
    case dark = "Dark"
    case midnight = "Midnight"
    case oled = "OLED"
    case light = "Light"
    case system = "System"
    
    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .midnight: return "moon.stars.fill"
        case .oled: return "circle.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .dark: return Color(hex: "1A1A1A")
        case .midnight: return Color(hex: "0A0F1A")
        case .oled: return .black
        case .light: return Color(hex: "F5F5F5")
        case .system: return Color(hex: "2A2A2A")
        }
    }
    
    /// The background color used across the app
    var backgroundColor: Color {
        switch self {
        case .dark: return Color(hex: "0D0D0D")
        case .midnight: return Color(hex: "0A0F1A")
        case .oled: return .black
        case .light: return Color(hex: "F2F2F7")
        case .system: return Color(hex: "0D0D0D")
        }
    }
    
    /// Secondary background for cards
    var cardColor: Color {
        switch self {
        case .dark: return Color.white.opacity(0.04)
        case .midnight: return Color(hex: "111827")
        case .oled: return Color.white.opacity(0.03)
        case .light: return .white
        case .system: return Color.white.opacity(0.04)
        }
    }
    
    /// Primary text color
    var textColor: Color {
        switch self {
        case .dark, .midnight, .oled, .system: return .white
        case .light: return .black
        }
    }
    
    /// Secondary text color
    var secondaryTextColor: Color {
        switch self {
        case .dark, .midnight, .oled, .system: return .white.opacity(0.5)
        case .light: return .black.opacity(0.5)
        }
    }
    
    /// The SwiftUI color scheme
    var colorScheme: ColorScheme? {
        switch self {
        case .dark, .midnight, .oled: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
    
    var displayName: String {
        rawValue
    }
    
    var themeColor: Color {
        switch self {
        case .dark, .midnight, .oled, .system: return Color(hex: "0D0D0D")
        case .light: return Color(hex: "F2F2F7")
        }
    }
}
