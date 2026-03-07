import Foundation
import Observation

@Observable
final class TabViewModel {
    var selectedTab: Tab = .dashboard
    var previousTab: Tab?
    
    /// Tabs shown in the main bottom tab bar
    enum Tab: String, CaseIterable {
        case dashboard = "Home"
        case chat = "Chat"
        case afl = "AFL"
        case knowledge = "KB"
        case settings = "More"
        
        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .chat: return "message"
            case .afl: return "chevron.left.forwardslash.chevron.right"
            case .knowledge: return "cylinder"
            case .settings: return "ellipsis.circle"
            }
        }

        var selectedIcon: String {
            switch self {
            case .dashboard: return "square.grid.2x2.fill"
            case .chat: return "message.fill"
            case .afl: return "chevron.left.forwardslash.chevron.right"
            case .knowledge: return "cylinder.fill"
            case .settings: return "ellipsis.circle.fill"
            }
        }
    }
    
    /// Feature destinations accessible via NavigationStack push (not in tab bar)
    enum Feature: String, Hashable {
        case backtest = "Backtest Analysis"
        case research = "Company Research"
        case presentations = "Presentations"
        
        var icon: String {
            switch self {
            case .backtest: return "chart.line.uptrend.xyaxis"
            case .research: return "magnifyingglass.circle"
            case .presentations: return "doc.richtext"
            }
        }
        
        var iconColor: String {
            switch self {
            case .backtest: return "34D399"
            case .research: return "3B82F6"
            case .presentations: return "F472B6"
            }
        }
    }
    
    func select(_ tab: Tab) {
        HapticManager.shared.selection()
        previousTab = selectedTab
        selectedTab = tab
    }
    
    func goBack() {
        if let previous = previousTab {
            selectedTab = previous
            previousTab = nil
        }
    }
}
