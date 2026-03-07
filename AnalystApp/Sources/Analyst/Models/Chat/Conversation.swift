import Foundation

struct Conversation: Identifiable, Codable, Hashable {
    let id: String
    let userId: String?
    var title: String
    let conversationType: String?
    let createdAt: Date
    var updatedAt: Date?
    var messageCount: Int?
    var lastMessage: String?
    
    var displayTitle: String {
        if title.isEmpty {
            return "New Conversation"
        }
        return title
    }
    
    var formattedDate: String {
        let date = updatedAt ?? createdAt
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Create Conversation Request

struct CreateConversationRequest: Codable {
    let title: String?
    let conversationType: String?
}

// MARK: - Rename Conversation Request

struct RenameConversationRequest: Codable {
    let title: String
}