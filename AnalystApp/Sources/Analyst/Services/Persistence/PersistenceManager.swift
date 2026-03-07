import Foundation
import SwiftData

// MARK: - Persistence Manager

/// Manages local data persistence with SwiftData
@MainActor
final class PersistenceManager {
    static let shared = PersistenceManager()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private init() {
        let schema = Schema([
            CachedConversation.self,
            CachedMessage.self,
            DraftMessage.self,
            CachedDocument.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }
    
    // MARK: - Convenience Methods
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("⚠️ PersistenceManager: Save failed: \(error)")
        }
    }
    
    func deleteAll<T: PersistentModel>(_ type: T.Type) {
        try? modelContext.delete(model: type)
    }
}

// MARK: - Cached Models

@Model
final class CachedConversation {
    @Attribute(.unique) var id: String
    var userId: String?
    var title: String
    var conversationType: String?
    var createdAt: Date
    var updatedAt: Date?
    var messageCount: Int
    var lastMessage: String?
    
    @Relationship(deleteRule: .cascade)
    var messages: [CachedMessage] = []
    
    init(
        id: String,
        userId: String? = nil,
        title: String,
        conversationType: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        messageCount: Int = 0,
        lastMessage: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.conversationType = conversationType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
        self.lastMessage = lastMessage
    }
    
    convenience init(from conversation: Conversation) {
        self.init(
            id: conversation.id,
            userId: conversation.userId,
            title: conversation.title,
            conversationType: conversation.conversationType,
            createdAt: conversation.createdAt,
            updatedAt: conversation.updatedAt,
            messageCount: conversation.messageCount ?? 0,
            lastMessage: conversation.lastMessage
        )
    }
    
    var toConversation: Conversation {
        Conversation(
            id: id,
            userId: userId,
            title: title,
            conversationType: conversationType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messageCount: messageCount,
            lastMessage: lastMessage
        )
    }
}

@Model
final class CachedMessage {
    @Attribute(.unique) var id: String
    var conversationId: String
    var role: String
    var content: String
    var createdAt: Date
    var metadataJson: Data?
    
    var conversation: CachedConversation?
    
    init(
        id: String,
        conversationId: String,
        role: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
    
    convenience init(from message: Message) {
        self.init(
            id: message.id,
            conversationId: message.conversationId,
            role: message.role.rawValue,
            content: message.content,
            createdAt: message.createdAt
        )
        self.metadataJson = try? JSONEncoder().encode(message.metadata)
    }
    
    var toMessage: Message {
        Message(
            id: id,
            conversationId: conversationId,
            role: MessageRole(rawValue: role) ?? .user,
            content: content,
            createdAt: createdAt,
            metadata: metadataJson.flatMap { try? JSONDecoder().decode(MessageMetadata.self, from: $0) }
        )
    }
}

@Model
final class DraftMessage {
    @Attribute(.unique) var conversationId: String
    var content: String
    var attachmentsJson: Data?
    var updatedAt: Date
    
    init(conversationId: String, content: String = "") {
        self.conversationId = conversationId
        self.content = content
        self.updatedAt = Date()
    }
}

@Model
final class CachedDocument {
    @Attribute(.unique) var id: String
    var title: String?
    var filename: String?
    var category: String?
    var summary: String?
    var fileSize: Int
    var createdAt: Date
    var cachedAt: Date
    
    init(
        id: String,
        title: String? = nil,
        filename: String? = nil,
        category: String? = nil,
        summary: String? = nil,
        fileSize: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.filename = filename
        self.category = category
        self.summary = summary
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.cachedAt = Date()
    }
    
    convenience init(from document: KnowledgeDocument) {
        self.init(
            id: document.id,
            title: document.title,
            filename: document.filename,
            category: document.category,
            summary: document.summary,
            fileSize: document.fileSize ?? 0,
            createdAt: document.createdAt ?? Date()
        )
    }
}

// MARK: - Local Data Service

@MainActor
final class LocalDataService {
    static let shared = LocalDataService()
    
    private let persistence = PersistenceManager.shared
    private var modelContext: ModelContext { persistence.modelContext }
    
    // MARK: - Conversations
    
    func cacheConversations(_ conversations: [Conversation]) {
        for conversation in conversations {
            let cached = CachedConversation(from: conversation)
            modelContext.insert(cached)
        }
        persistence.save()
    }
    
    func getCachedConversations() -> [Conversation] {
        let descriptor = FetchDescriptor<CachedConversation>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            let cached = try modelContext.fetch(descriptor)
            return cached.map { $0.toConversation }
        } catch {
            print("⚠️ LocalDataService: Failed to fetch conversations: \(error)")
            return []
        }
    }
    
    func cacheMessages(_ messages: [Message], for conversationId: String) {
        // Clear existing messages for this conversation
        let existingDescriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.conversationId == conversationId }
        )
        try? modelContext.delete(model: CachedMessage.self, where: existingDescriptor.predicate)
        
        // Insert new messages
        for message in messages {
            let cached = CachedMessage(from: message)
            modelContext.insert(cached)
        }
        
        persistence.save()
    }
    
    func getCachedMessages(for conversationId: String) -> [Message] {
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.conversationId == conversationId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let cached = try modelContext.fetch(descriptor)
            return cached.map { $0.toMessage }
        } catch {
            print("⚠️ LocalDataService: Failed to fetch messages: \(error)")
            return []
        }
    }
    
    // MARK: - Drafts
    
    func saveDraft(_ content: String, for conversationId: String) {
        let descriptor = FetchDescriptor<DraftMessage>(
            predicate: #Predicate { $0.conversationId == conversationId }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.content = content
            existing.updatedAt = Date()
        } else {
            let draft = DraftMessage(conversationId: conversationId, content: content)
            modelContext.insert(draft)
        }
        
        persistence.save()
    }
    
    func getDraft(for conversationId: String) -> String? {
        let descriptor = FetchDescriptor<DraftMessage>(
            predicate: #Predicate { $0.conversationId == conversationId }
        )
        
        return try? modelContext.fetch(descriptor).first?.content
    }
    
    func clearDraft(for conversationId: String) {
        let descriptor = FetchDescriptor<DraftMessage>(
            predicate: #Predicate { $0.conversationId == conversationId }
        )
        
        if let draft = try? modelContext.fetch(descriptor).first {
            modelContext.delete(draft)
            persistence.save()
        }
    }
    
    // MARK: - Cleanup
    
    func clearAllCachedData() {
        persistence.deleteAll(CachedConversation.self)
        persistence.deleteAll(CachedMessage.self)
        persistence.deleteAll(DraftMessage.self)
        persistence.deleteAll(CachedDocument.self)
        persistence.save()
    }
}