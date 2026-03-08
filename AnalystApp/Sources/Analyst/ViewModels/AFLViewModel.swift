import Foundation
import Observation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - AFL View Model

/// Manages AFL code generation, history, and clipboard operations.
///
/// ## Error Handling
/// - Errors are stored as `Error?` and exposed via `userFacingError` for UI.
/// - `clearError()` resets error state after user dismissal.
@Observable
final class AFLViewModel {
    // MARK: - State

    var prompt: String = ""
    var generatedCode: String = ""
    var explanation: String = ""
    var aflStats: AFLStats?
    var isGenerating: Bool = false
    var error: Error?
    var showCopied: Bool = false
    var history: [AFLHistoryEntry] = []
    var isLoadingHistory: Bool = false

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

    // MARK: - Generate AFL

    /// Generates AFL code from the current prompt.
    @MainActor
    func generateCode() async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = APIError.clientError("Please enter a prompt to generate AFL code.")
            return
        }

        isGenerating = true
        generatedCode = ""
        explanation = ""
        aflStats = nil
        error = nil
        hapticManager.lightImpact()

        do {
            let response = try await apiClient.generateAFL(prompt: trimmed)
            generatedCode = response.generatedCode
            explanation = response.explanation ?? ""
            aflStats = response.stats
            hapticManager.success()
        } catch {
            self.error = error
            hapticManager.error()
        }

        isGenerating = false
    }

    // MARK: - Copy to Clipboard

    /// Copies the generated code to the system clipboard.
    func copyCode() {
        guard !generatedCode.isEmpty else { return }
        #if os(iOS)
        UIPasteboard.general.string = generatedCode
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedCode, forType: .string)
        #endif
        showCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { showCopied = false }
        }
        hapticManager.lightImpact()
    }

    // MARK: - Load History

    /// Loads the AFL generation history from the server.
    @MainActor
    func loadHistory() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        do {
            history = try await apiClient.getAFLHistory()
        } catch {
            // History loading is non-critical — don't show error to user
            #if DEBUG
            print("⚠️ AFL history load failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Delete History Item

    /// Deletes an AFL history entry.
    @MainActor
    func deleteHistoryItem(_ item: AFLHistoryEntry) async {
        do {
            try await apiClient.deleteAFLHistory(id: item.id)
            history.removeAll { $0.id == item.id }
        } catch {
            self.error = error
        }
    }

    // MARK: - Use History Item

    /// Loads a history item into the prompt and code fields.
    func useHistoryItem(_ item: AFLHistoryEntry) {
        prompt = item.prompt ?? ""
        generatedCode = item.code ?? ""
    }
}
