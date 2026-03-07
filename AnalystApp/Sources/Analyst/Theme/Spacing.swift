import SwiftUI

enum Spacing: CGFloat {
    case xxxs = 2
    case xxs = 4
    case xs = 6
    case sm = 8
    case md = 12
    case lg = 16
    case xl = 20
    case xxl = 24
    case xxxl = 32
    case huge = 48
}

extension CGFloat {
    static func spacing(_ spacing: Spacing) -> CGFloat {
        spacing.rawValue
    }
}

extension EdgeInsets {
    static func all(_ value: Spacing) -> EdgeInsets {
        EdgeInsets(top: value.rawValue, leading: value.rawValue, bottom: value.rawValue, trailing: value.rawValue)
    }
    
    static func horizontal(_ value: Spacing) -> EdgeInsets {
        EdgeInsets(top: 0, leading: value.rawValue, bottom: 0, trailing: value.rawValue)
    }
    
    static func vertical(_ value: Spacing) -> EdgeInsets {
        EdgeInsets(top: value.rawValue, leading: 0, bottom: value.rawValue, trailing: 0)
    }
}

// MARK: - Corner Radius

enum CornerRadius: CGFloat {
    case none = 0
    case xs = 4
    case sm = 6
    case md = 8
    case lg = 12
    case xl = 16
    case xxl = 20
    case full = 999
}

extension View {
    func cornerRadius(_ radius: CornerRadius) -> some View {
        self.cornerRadius(radius.rawValue)
    }
}