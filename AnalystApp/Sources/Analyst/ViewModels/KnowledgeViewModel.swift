import Foundation
import Observation

// MARK: - Knowledge View Model

/// Manages the knowledge base: document listing, upload, and deletion.
///
/// ## Error Handling
/// - Uses `Error?` with `userFacingError` computed property for consistent UI display.
/// - `clearError()` resets error state after user dismissal.
@Observable
final class KnowledgeViewModel {
    // MARK: - State

    var documents: [KnowledgeDocument] = []
    var stats: BrainStats?
    var isLoading: Bool = false
    var isUploading: Bool = false
    var uploadProgress: Double = 0
    var error: Error?
    var uploadSuccess: Bool = false

    /// User-friendly error message for UI display.
    var userFacingError: String? {
        guard let error else { return nil }
        if let apiError = error as? APIError {
            return apiError.errorDescription
        }
        return error.localizedDescription
    }

    /// Clears the current error state.
    func clearError() {
        error = nil
    }

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let hapticManager: HapticManager

    init(apiClient: APIClient = .shared, hapticManager: HapticManager = .shared) {
        self.apiClient = apiClient
        self.hapticManager = hapticManager
    }

    // MARK: - Load Documents

    /// Loads all documents and statistics from the knowledge base.
    @MainActor
    func loadDocuments() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            async let docs = apiClient.getDocuments()
            async let brainStats = apiClient.getBrainStats()

            documents = try await docs
            stats = try? await brainStats
        } catch {
            self.error = error
        }
    }

    // MARK: - Upload Document

    /// Uploads a document to the knowledge base.
    ///
    /// - Parameters:
    ///   - data: File data to upload.
    ///   - filename: The original filename.
    ///   - category: Document category (default: "general").
    @MainActor
    func uploadDocument(data: Data, filename: String, category: String = "general") async {
        guard !data.isEmpty else {
            error = APIError.clientError("File data is empty.")
            return
        }
        guard !filename.isEmpty else {
            error = APIError.clientError("Filename cannot be empty.")
            return
        }

        isUploading = true
        uploadProgress = 0
        uploadSuccess = false
        error = nil
        hapticManager.lightImpact()

        // Simulate incremental progress for UX (small file uploads are near-instant)
        let progressTask = Task {
            for i in 1...8 {
                guard !Task.isCancelled else { break }
                try? await Task.sleep(nanoseconds: 150_000_000)
                uploadProgress = Double(i) / 10.0
            }
        }

        do {
            _ = try await apiClient.uploadDocument(data: data, filename: filename, category: category)
            progressTask.cancel()
            uploadProgress = 1.0
            uploadSuccess = true
            hapticManager.success()
            // Reload documents after upload
            try? await Task.sleep(nanoseconds: 500_000_000)
            await loadDocuments()
        } catch {
            progressTask.cancel()
            self.error = error
            hapticManager.error()
        }

        isUploading = false
    }

    // MARK: - Delete Document

    /// Deletes a document from the knowledge base.
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
            self.error = error
        }
    }

    // MARK: - Computed Properties

    /// Formatted total size of all documents.
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

    /// Total number of documents (from stats or local count).
    var documentCount: Int {
        stats?.totalDocuments ?? documents.count
    }
}

// MARK: - KnowledgeDocument Helpers

extension KnowledgeDocument {
    /// Display name with fallback to filename or "Untitled".
    var displayName: String {
        title ?? filename ?? "Untitled"
    }

    /// File extension extracted from the filename.
    var fileExtension: String {
        guard let name = filename else { return "doc" }
        return (name as NSString).pathExtension.lowercased()
    }

    /// SF Symbol name based on file type.
    var iconName: String {
        switch fileExtension {
        case "pdf": return "doc.fill"
        case "txt", "md": return "doc.text"
        case "csv": return "tablecells"
        case "json": return "curlybraces"
        default: return "doc"
        }
    }

    /// Icon color based on file type.
    var iconColor: Color {
        switch fileExtension {
        case "pdf": return .red
        case "txt", "md": return .blue
        case "csv": return .green
        case "json": return .orange
        default: return .gray
        }
    }

    /// Formatted file size string.
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

    /// Formatted creation date string.
    var formattedDate: String {
        guard let date = createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

import SwiftUI
