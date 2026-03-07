import SwiftUI

extension Font {
    // MARK: - Rajdhani (Headings)
    
    static func rajdhani(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let fontName = rajdhaniFontName(for: weight)
        return .custom(fontName, size: size)
    }
    
    static func rajdhaniBold(_ size: CGFloat) -> Font {
        .custom("Rajdhani-Bold", size: size)
    }
    
    static func rajdhaniSemiBold(_ size: CGFloat) -> Font {
        .custom("Rajdhani-SemiBold", size: size)
    }
    
    static func rajdhaniMedium(_ size: CGFloat) -> Font {
        .custom("Rajdhani-Medium", size: size)
    }
    
    static func rajdhaniRegular(_ size: CGFloat) -> Font {
        .custom("Rajdhani-Regular", size: size)
    }
    
    // MARK: - Quicksand (Body)
    
    static func quicksand(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName = quicksandFontName(for: weight)
        return .custom(fontName, size: size)
    }
    
    static func quicksandBold(_ size: CGFloat) -> Font {
        .custom("Quicksand-Bold", size: size)
    }
    
    static func quicksandSemiBold(_ size: CGFloat) -> Font {
        .custom("Quicksand-SemiBold", size: size)
    }
    
    static func quicksandMedium(_ size: CGFloat) -> Font {
        .custom("Quicksand-Medium", size: size)
    }
    
    static func quicksandRegular(_ size: CGFloat) -> Font {
        .custom("Quicksand-Regular", size: size)
    }
    
    // MARK: - Fira Code (Monospace)
    
    static func firaCode(_ size: CGFloat) -> Font {
        .custom("FiraCode-Regular", size: size)
    }
    
    static func firaCodeMedium(_ size: CGFloat) -> Font {
        .custom("FiraCode-Medium", size: size)
    }
    
    // MARK: - Helper Methods
    
    private static func rajdhaniFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold: return "Rajdhani-Bold"
        case .semibold: return "Rajdhani-SemiBold"
        case .medium: return "Rajdhani-Medium"
        default: return "Rajdhani-Regular"
        }
    }
    
    private static func quicksandFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold: return "Quicksand-Bold"
        case .semibold: return "Quicksand-SemiBold"
        case .medium: return "Quicksand-Medium"
        default: return "Quicksand-Regular"
        }
    }
}

// MARK: - Text Styles

enum TextStyle {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2
    
    var font: Font {
        switch self {
        case .largeTitle:
            return .rajdhani(34, weight: .bold)
        case .title1:
            return .rajdhani(28, weight: .bold)
        case .title2:
            return .rajdhani(22, weight: .bold)
        case .title3:
            return .rajdhani(18, weight: .semibold)
        case .headline:
            return .rajdhani(16, weight: .semibold)
        case .body:
            return .quicksand(16, weight: .regular)
        case .callout:
            return .quicksand(15, weight: .regular)
        case .subheadline:
            return .quicksand(14, weight: .regular)
        case .footnote:
            return .quicksand(12, weight: .regular)
        case .caption1:
            return .quicksand(11, weight: .regular)
        case .caption2:
            return .quicksand(10, weight: .regular)
        }
    }
}

// MARK: - View Extension

extension View {
    func textStyle(_ style: TextStyle) -> some View {
        font(style.font)
    }
}