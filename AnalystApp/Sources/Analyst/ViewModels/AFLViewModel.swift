import Foundation
import Observation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@Observable
final class AFLViewModel {
    // MARK: - State
    var prompt: String = ""
    var generatedCode: String = ""
    var explanation: String = ""
    var aflStats: AFLStats?
    var isGenerating: Bool = false
    var error: String?
    var showCopied: Bool = false
    var history: [AFLHistoryEntry] = []
    var isLoadingHistory: Bool = false

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let hapticManager: HapticManager

    init(apiClient: APIClient = .shared, hapticManager: HapticManager = .shared) {
        self.apiClient = apiClient
        self.hapticManager = hapticManager
    }

    // MARK: - Generate AFL

    @MainActor
    func generateCode() async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

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
            self.error = error.localizedDescription
            hapticManager.error()
        }

        isGenerating = false
    }

    // MARK: - Copy to Clipboard

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

    @MainActor
    func loadHistory() async {
        isLoadingHistory = true
        do {
            history = try await apiClient.getAFLHistory()
        } catch {
            // Not critical — history may be empty
        }
        isLoadingHistory = false
    }

    // MARK: - Delete History Item

    @MainActor
    func deleteHistoryItem(_ item: AFLHistoryEntry) async {
        do {
            try await apiClient.deleteAFLHistory(id: item.id)
            history.removeAll { $0.id == item.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Use History Item

    func useHistoryItem(_ item: AFLHistoryEntry) {
        prompt = item.prompt ?? ""
        generatedCode = item.code ?? ""
    }
}
