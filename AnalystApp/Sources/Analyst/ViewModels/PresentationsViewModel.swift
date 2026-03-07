import Foundation
import Observation

@Observable
final class PresentationsViewModel {
    // MARK: - State
    var title: String = ""
    var subtitle: String = ""
    var slides: [PresentationSlide] = [PresentationSlide()]
    var theme: PresentationTheme = .dark
    var isGenerating: Bool = false
    var generatedId: String?
    var downloadURL: String?
    var error: String?

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let hapticManager: HapticManager

    init(apiClient: APIClient = .shared, hapticManager: HapticManager = .shared) {
        self.apiClient = apiClient
        self.hapticManager = hapticManager
    }

    // MARK: - Slide Management

    func addSlide() {
        slides.append(PresentationSlide())
        hapticManager.lightImpact()
    }

    func removeSlide(at index: Int) {
        guard slides.count > 1, slides.indices.contains(index) else { return }
        slides.remove(at: index)
        hapticManager.lightImpact()
    }

    func moveSlide(from source: IndexSet, to destination: Int) {
        slides.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Generate

    @MainActor
    func generate() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            error = "Please enter a presentation title."
            return
        }
        guard slides.contains(where: { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            error = "Please add at least one slide with a title."
            return
        }

        isGenerating = true
        error = nil
        generatedId = nil
        downloadURL = nil
        hapticManager.lightImpact()

        do {
            let slidesPayload: [[String: Any]] = slides.map { slide in
                var dict: [String: Any] = ["title": slide.title]
                dict["bullets"] = slide.bullets.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                if !slide.notes.isEmpty { dict["notes"] = slide.notes }
                return dict
            }

            let body: [String: Any] = [
                "title": trimmedTitle,
                "subtitle": subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                "theme": theme.rawValue,
                "slides": slidesPayload
            ]

            let data = try await apiClient.performRequest(.post, APIEndpoints.Presentation.generate, body: body)
            let response = try JSONDecoder().decode(PresentationGenerateResponse.self, from: data)
            generatedId = response.id
            downloadURL = response.downloadUrl
            hapticManager.success()
        } catch {
            self.error = error.localizedDescription
            hapticManager.error()
        }

        isGenerating = false
    }

    // MARK: - Download

    @MainActor
    func download() async -> Data? {
        guard let id = generatedId else { return nil }

        do {
            let data = try await apiClient.performRequest(.get, APIEndpoints.Presentation.download(id))
            hapticManager.success()
            return data
        } catch {
            self.error = error.localizedDescription
            hapticManager.error()
            return nil
        }
    }

    // MARK: - Reset

    func reset() {
        title = ""
        subtitle = ""
        slides = [PresentationSlide()]
        theme = .dark
        generatedId = nil
        downloadURL = nil
        error = nil
    }
}

// MARK: - Models

struct PresentationSlide: Identifiable {
    let id = UUID()
    var title: String = ""
    var bullets: String = ""
    var notes: String = ""
}

enum PresentationTheme: String, CaseIterable, Identifiable {
    case dark
    case light
    case corporate
    case potomac

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .corporate: return "Corporate"
        case .potomac: return "Potomac"
        }
    }
}

struct PresentationGenerateResponse: Codable {
    let id: String?
    let status: String?
    let downloadUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case downloadUrl = "download_url"
    }
}
