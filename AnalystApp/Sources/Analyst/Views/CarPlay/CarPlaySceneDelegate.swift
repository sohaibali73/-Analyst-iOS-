import Foundation

#if canImport(CarPlay) && os(iOS)
import CarPlay

// MARK: - CarPlay Scene Delegate

/// Manages the CarPlay interface for Analyst.
/// CarPlay shows a simplified, voice-driven chat experience for safe in-car use.
///
/// To enable CarPlay:
/// 1. Add the CarPlay entitlement in Xcode (com.apple.developer.carplay-messaging)
/// 2. Add a CPTemplateApplicationSceneSessionRoleApplication scene configuration in Info.plist
/// 3. Set this class as the delegate for the CarPlay scene
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    
    // MARK: - Scene Lifecycle
    
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        print("🚗 CarPlay connected")
        
        // Set the root template
        let rootTemplate = buildRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)
    }
}

// MARK: - CarPlay Disconnect (in extension to silence protocol matching warning)

extension CarPlaySceneDelegate {
    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        print("🚗 CarPlay disconnected")
    }
    
    // MARK: - Root Template
    
    private func buildRootTemplate() -> CPTabBarTemplate {
        let chatTab = buildChatTab()
        let marketTab = buildMarketTab()
        
        let tabBar = CPTabBarTemplate(templates: [chatTab, marketTab])
        return tabBar
    }
    
    // MARK: - Chat Tab
    
    private func buildChatTab() -> CPListTemplate {
        let quickPrompts = [
            "What's the market outlook today?",
            "Give me a summary of my portfolio",
            "What are the top movers?",
            "Any breaking market news?"
        ]
        
        let items = quickPrompts.map { prompt in
            let item = CPListItem(
                text: prompt,
                detailText: "Tap to ask Yang"
            )
            item.handler = { [weak self] _, completion in
                self?.sendCarPlayMessage(prompt)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Ask Yang", sections: [section])
        template.tabSystemItem = .featured
        template.tabTitle = "Chat"
        template.tabImage = UIImage(systemName: "bubble.left.fill")
        
        return template
    }
    
    // MARK: - Market Tab
    
    private func buildMarketTab() -> CPListTemplate {
        let marketItems: [CPListItem] = [
            CPListItem(text: "S&P 500", detailText: "Loading..."),
            CPListItem(text: "NASDAQ", detailText: "Loading..."),
            CPListItem(text: "Dow Jones", detailText: "Loading..."),
            CPListItem(text: "Bitcoin", detailText: "Loading...")
        ]
        
        let section = CPListSection(items: marketItems, header: "Market Overview", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Markets", sections: [section])
        template.tabSystemItem = .search
        template.tabTitle = "Markets"
        template.tabImage = UIImage(systemName: "chart.line.uptrend.xyaxis")
        
        return template
    }
    
    // MARK: - Actions
    
    private func sendCarPlayMessage(_ text: String) {
        // Show a loading state
        let loadingItem = CPListItem(text: "Asking Yang...", detailText: text)
        let loadingSection = CPListSection(items: [loadingItem])
        let loadingTemplate = CPListTemplate(title: "Response", sections: [loadingSection])
        
        interfaceController?.pushTemplate(loadingTemplate, animated: true, completion: nil)
        
        // Send the message via ChatViewModel
        Task { @MainActor in
            let chatVM = ChatViewModel()
            
            // Ensure we have a conversation
            await chatVM.loadOrCreateConversation()
            await chatVM.sendMessage(text)
            
            // Wait for response (simplified for CarPlay)
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            // Show the response
            let response = chatVM.messages.last?.content ?? "No response received."
            let responseItem = CPListItem(text: "Yang", detailText: String(response.prefix(200)))
            let responseSection = CPListSection(items: [responseItem])
            let responseTemplate = CPListTemplate(title: "Response", sections: [responseSection])
            
            self.interfaceController?.popToRootTemplate(animated: false, completion: nil)
            self.interfaceController?.pushTemplate(responseTemplate, animated: true, completion: nil)
        }
    }
}

#endif
