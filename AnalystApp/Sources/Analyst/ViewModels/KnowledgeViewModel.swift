import Foundation
import Observation

@Observable
final class KnowledgeViewModel {
    // MARK: - State
    var documents: [KnowledgeDocument] = []
    var stats: BrainStats?
    var isLoading: Bool = false
    var isUploading: Bool = false
    var uploadProgress: Double = 0
    var error: String?
    var uploadSuccess: Bool = false

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let hapticManager: HapticManager

    init(apiClient: APIClient = .shared, hapticManager: HapticManager = .shared) {
        self.apiClient = apiClient
        self.hapticManager = hapticManager
    }

    // MARK: - Load Documents

    @MainActor
    func loadDocuments() async {
        isLoading = true
        error = nil

        do {
            async let docs = apiClient.getDocuments()
            async let brainStats = apiClient.getBrainStats()

            documents = try await docs
            stats = try? await brainStats
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Upload Document

    @MainActor
    func uploadDocument(data: Data, filename: String, category: String = "general") async {
        isUploading = true
        uploadProgress = 0
        uploadSuccess = false
        error = nil
        hapticManager.lightImpact()

        // Simulate progress since URLSession doesn't give easy upload progress for small files
        Task {
            for i in 1...8 {
                try? await Task.sleep(nanoseconds: 150_000_000)
                uploadProgress = Double(i) / 10.0
            }
        }

        do {
            _ = try await apiClient.uploadDocument(data: data, filename: filename, category: category)
            uploadProgress = 1.0
            uploadSuccess = true
            hapticManager.success()
            // Reload documents after upload
            try? await Task.sleep(nanoseconds: 500_000_000)
            await loadDocuments()
        } catch {
            self.error = error.localizedDescription
            hapticManager.error()
        }

        isUploading = false
    }

    // MARK: - Delete Document

    @MainActor
    func deleteDocument(_ document: KnowledgeDocument) async {
        do {
            try await apiClient.deleteDocument(id: document.id)
            documents.removeAll { $0.id == document.id }
            // Update stats locally
            if let stats = stats {
                self.stats = BrainStats(
                    totalDocuments: max(0, stats.totalDocuments - 1),
                    totalSize: stats.totalSize,
                    totalChunks: stats.totalChunks,
                    totalLearnings: stats.totalLearnings,
                    categories: stats.categories
                )
            }
            hapticManager.lightImpact()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Computed Properties

    var formattedTotalSize: String {
        guard let stats = stats else { return "0 KB" }
        let bytes = stats.totalSize
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }

    var documentCount: Int {
        stats?.totalDocuments ?? documents.count
    }
}

// MARK: - KnowledgeDocument Helpers

extension KnowledgeDocument {
    var displayName: String {
        title ?? filename ?? "Untitled"
    }

    var fileExtension: String {
        guard let name = filename else { return "doc" }
        return (name as NSString).pathExtension.lowercased()
    }

    var iconName: String {
        switch fileExtension {
        case "pdf": return "doc.fill"
        case "txt", "md": return "doc.text"
        case "csv": return "tablecells"
        case "json": return "curlybraces"
        default: return "doc"
        }
    }

    var iconColor: Color {
        switch fileExtension {
        case "pdf": return .red
        case "txt", "md": return .blue
        case "csv": return .green
        case "json": return .orange
        default: return .gray
        }
    }

    var formattedSize: String {
        guard let size = fileSize else { return "" }
        if size < 1024 {
            return "\(size) B"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024 * 1024))
        }
    }

    var formattedDate: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

import SwiftUI
