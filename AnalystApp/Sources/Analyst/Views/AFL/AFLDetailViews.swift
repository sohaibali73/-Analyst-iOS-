import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - AFL Optimize View

struct AFLOptimizeView: View {
    let code: String
    @State private var optimizedCode = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    private let apiClient = APIClient.shared

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                aflDetailNavBar(title: "OPTIMIZE", dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Original code preview
                        codePreviewSection(title: "ORIGINAL CODE", code: code)

                        // Error
                        if let error = error {
                            aflErrorBanner(error) { self.error = nil }
                        }

                        // Result
                        if isLoading {
                            aflLoadingSection(message: "Optimizing your AFL code...")
                        } else if !optimizedCode.isEmpty {
                            aflResultCodeSection(
                                title: "OPTIMIZED CODE",
                                code: optimizedCode,
                                showCopied: $showCopied,
                                onCopy: { copyToClipboard(optimizedCode) }
                            )
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Action button
                aflActionButton(
                    title: "OPTIMIZE CODE",
                    icon: "bolt.fill",
                    isLoading: isLoading
                ) {
                    await optimize()
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }

    @MainActor
    private func optimize() async {
        isLoading = true
        error = nil
        optimizedCode = ""

        do {
            let body: [String: Any] = ["code": code]
            let data = try await performRequest(.post, endpoint: APIEndpoints.AFL.optimize, body: body)
            if let response = try? JSONDecoder().decode(AFLActionResponse.self, from: data) {
                optimizedCode = response.code ?? response.result ?? ""
            }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

// MARK: - AFL Debug View

struct AFLDebugView: View {
    let code: String
    let errorMessage: String
    @State private var fixedCode = ""
    @State private var debugExplanation = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                aflDetailNavBar(title: "DEBUG", dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Original code
                        codePreviewSection(title: "ORIGINAL CODE", code: code)

                        // Error message input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ERROR MESSAGE")
                                .font(.custom("Quicksand-SemiBold", size: 10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)

                            Text(errorMessage)
                                .font(.custom("FiraCode-Regular", size: 12))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                                )
                        }

                        // Error
                        if let error = error {
                            aflErrorBanner(error) { self.error = nil }
                        }

                        // Debug explanation
                        if !debugExplanation.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DIAGNOSIS")
                                    .font(.custom("Quicksand-SemiBold", size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                                    .tracking(1.5)

                                Text(debugExplanation)
                                    .font(.custom("Quicksand-Regular", size: 13))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(10)
                            }
                        }

                        // Result
                        if isLoading {
                            aflLoadingSection(message: "Debugging your AFL code...")
                        } else if !fixedCode.isEmpty {
                            aflResultCodeSection(
                                title: "FIXED CODE",
                                code: fixedCode,
                                showCopied: $showCopied,
                                onCopy: { copyToClipboard(fixedCode) }
                            )
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Action button
                aflActionButton(
                    title: "DEBUG CODE",
                    icon: "ant.fill",
                    isLoading: isLoading
                ) {
                    await debug()
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }

    @MainActor
    private func debug() async {
        isLoading = true
        error = nil
        fixedCode = ""
        debugExplanation = ""

        do {
            let body: [String: Any] = ["code": code, "error_message": errorMessage]
            let data = try await performRequest(.post, endpoint: APIEndpoints.AFL.debug, body: body)
            if let response = try? JSONDecoder().decode(AFLDebugResponse.self, from: data) {
                fixedCode = response.fixedCode ?? response.code ?? ""
                debugExplanation = response.explanation ?? ""
            }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

// MARK: - AFL Explain View

struct AFLExplainView: View {
    let code: String
    @State private var explanation = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                aflDetailNavBar(title: "EXPLAIN", dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Original code
                        codePreviewSection(title: "ORIGINAL CODE", code: code)

                        // Error
                        if let error = error {
                            aflErrorBanner(error) { self.error = nil }
                        }

                        // Result
                        if isLoading {
                            aflLoadingSection(message: "Analyzing your AFL code...")
                        } else if !explanation.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("EXPLANATION")
                                        .font(.custom("Quicksand-SemiBold", size: 10))
                                        .foregroundColor(.white.opacity(0.4))
                                        .tracking(1.5)
                                    Spacer()
                                    Button {
                                        copyToClipboard(explanation)
                                        showCopied = true
                                        Task {
                                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                                            await MainActor.run { showCopied = false }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 11))
                                            Text(showCopied ? "Copied!" : "Copy")
                                                .font(.custom("Quicksand-SemiBold", size: 11))
                                        }
                                        .foregroundColor(showCopied ? .green : Color.potomacYellow)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.potomacYellow.opacity(0.1))
                                        .cornerRadius(7)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text(explanation)
                                    .font(.custom("Quicksand-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineSpacing(5)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Action button
                aflActionButton(
                    title: "EXPLAIN CODE",
                    icon: "text.magnifyingglass",
                    isLoading: isLoading
                ) {
                    await explain()
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }

    @MainActor
    private func explain() async {
        isLoading = true
        error = nil
        explanation = ""

        do {
            let body: [String: Any] = ["code": code]
            let data = try await performRequest(.post, endpoint: APIEndpoints.AFL.explain, body: body)
            if let response = try? JSONDecoder().decode(AFLActionResponse.self, from: data) {
                explanation = response.explanation ?? response.result ?? ""
            }
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

// MARK: - AFL Validate View

struct AFLValidateView: View {
    let code: String
    @State private var validationResult: AFLValidationResult?
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                aflDetailNavBar(title: "VALIDATE", dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Original code
                        codePreviewSection(title: "CODE TO VALIDATE", code: code)

                        // Error
                        if let error = error {
                            aflErrorBanner(error) { self.error = nil }
                        }

                        // Result
                        if isLoading {
                            aflLoadingSection(message: "Validating your AFL code...")
                        } else if let result = validationResult {
                            validationResultSection(result)
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Action button
                aflActionButton(
                    title: "VALIDATE CODE",
                    icon: "checkmark.shield.fill",
                    isLoading: isLoading
                ) {
                    await validate()
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }

    @ViewBuilder
    private func validationResultSection(_ result: AFLValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Status badge
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(result.isValid ? Color.success.opacity(0.15) : Color.error.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(result.isValid ? .success : .error)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.isValid ? "Valid" : "Invalid")
                        .font(.custom("Rajdhani-Bold", size: 18))
                        .foregroundColor(result.isValid ? .success : .error)

                    if let score = result.score {
                        Text("Score: \(score)%")
                            .font(.custom("Quicksand-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer()

                Button {
                    if let resultText = formatValidationResult(result) {
                        copyToClipboard(resultText)
                        showCopied = true
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            await MainActor.run { showCopied = false }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(showCopied ? "Copied!" : "Copy")
                            .font(.custom("Quicksand-SemiBold", size: 11))
                    }
                    .foregroundColor(showCopied ? .green : Color.potomacYellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.potomacYellow.opacity(0.1))
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )

            // Errors
            if let errors = result.errors, !errors.isEmpty {
                issuesSection(title: "ERRORS", items: errors, color: .error, icon: "xmark.circle.fill")
            }

            // Warnings
            if let warnings = result.warnings, !warnings.isEmpty {
                issuesSection(title: "WARNINGS", items: warnings, color: .warning, icon: "exclamationmark.triangle.fill")
            }

            // Suggestions
            if let suggestions = result.suggestions, !suggestions.isEmpty {
                issuesSection(title: "SUGGESTIONS", items: suggestions, color: .info, icon: "lightbulb.fill")
            }
        }
    }

    @ViewBuilder
    private func issuesSection(title: String, items: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(color)
                .tracking(1.5)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(color)
                        .padding(.top, 2)

                    Text(item)
                        .font(.custom("Quicksand-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.06))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    @MainActor
    private func validate() async {
        isLoading = true
        error = nil
        validationResult = nil

        do {
            let body: [String: Any] = ["code": code]
            let data = try await performRequest(.post, endpoint: APIEndpoints.AFL.validate, body: body)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            validationResult = try decoder.decode(AFLValidationResult.self, from: data)
            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }

    private func formatValidationResult(_ result: AFLValidationResult) -> String? {
        var lines: [String] = []
        lines.append("Validation: \(result.isValid ? "VALID" : "INVALID")")
        if let score = result.score { lines.append("Score: \(score)%") }
        if let errors = result.errors, !errors.isEmpty {
            lines.append("\nErrors:")
            errors.forEach { lines.append("  • \($0)") }
        }
        if let warnings = result.warnings, !warnings.isEmpty {
            lines.append("\nWarnings:")
            warnings.forEach { lines.append("  • \($0)") }
        }
        if let suggestions = result.suggestions, !suggestions.isEmpty {
            lines.append("\nSuggestions:")
            suggestions.forEach { lines.append("  • \($0)") }
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Response Models

struct AFLActionResponse: Codable {
    let code: String?
    let result: String?
    let explanation: String?
}

struct AFLDebugResponse: Codable {
    let fixedCode: String?
    let code: String?
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case fixedCode = "fixed_code"
        case code
        case explanation
    }
}

struct AFLValidationResult: Codable {
    let isValid: Bool
    let score: Int?
    let errors: [String]?
    let warnings: [String]?
    let suggestions: [String]?

    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case score
        case errors
        case warnings
        case suggestions
    }
}

// MARK: - Shared AFL Detail Components

@ViewBuilder
private func aflDetailNavBar(title: String, dismiss: DismissAction) -> some View {
    HStack {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 36, height: 36)
        }

        Spacer()

        Text(title)
            .font(.custom("Rajdhani-Bold", size: 16))
            .foregroundColor(.white)
            .tracking(3)

        Spacer()

        // Invisible spacer to center title
        Color.clear.frame(width: 36, height: 36)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)

    Divider().background(Color.white.opacity(0.07))
}

@ViewBuilder
private func codePreviewSection(title: String, code: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.custom("Quicksand-SemiBold", size: 10))
            .foregroundColor(.white.opacity(0.4))
            .tracking(1.5)

        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.custom("FiraCode-Regular", size: 11))
                .foregroundColor(Color(hex: "D4D4D4"))
                .padding(12)
        }
        .frame(maxHeight: 150)
        .background(Color(hex: "0A0A0A"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

@ViewBuilder
private func aflErrorBanner(_ message: String, onDismiss: @escaping () -> Void) -> some View {
    HStack(spacing: 10) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
        Text(message)
            .font(.custom("Quicksand-Regular", size: 13))
            .foregroundColor(.red.opacity(0.9))
            .lineLimit(3)
        Spacer()
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 12))
                .foregroundColor(.red.opacity(0.6))
        }
    }
    .padding(12)
    .background(Color.red.opacity(0.1))
    .cornerRadius(10)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.red.opacity(0.2), lineWidth: 1)
    )
}

@ViewBuilder
private func aflLoadingSection(message: String) -> some View {
    VStack(spacing: 14) {
        ProgressView().tint(Color.potomacYellow)
        Text(message)
            .font(.custom("Quicksand-Regular", size: 13))
            .foregroundColor(.white.opacity(0.4))
    }
    .frame(maxWidth: .infinity)
    .padding(32)
    .background(Color.white.opacity(0.03))
    .cornerRadius(12)
}

@ViewBuilder
private func aflResultCodeSection(
    title: String,
    code: String,
    showCopied: Binding<Bool>,
    onCopy: @escaping () -> Void
) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text(title)
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            Spacer()

            HStack(spacing: 8) {
                Button {
                    onCopy()
                    showCopied.wrappedValue = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run { showCopied.wrappedValue = false }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopied.wrappedValue ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(showCopied.wrappedValue ? "Copied!" : "Copy")
                            .font(.custom("Quicksand-SemiBold", size: 11))
                    }
                    .foregroundColor(showCopied.wrappedValue ? .green : Color.potomacYellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.potomacYellow.opacity(0.1))
                    .cornerRadius(7)
                }
                .buttonStyle(.plain)

                ShareLink(item: code) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }

        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.custom("FiraCode-Regular", size: 12))
                .foregroundColor(Color(hex: "D4D4D4"))
                .padding(16)
        }
        .background(Color(hex: "0A0A0A"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

@ViewBuilder
private func aflActionButton(
    title: String,
    icon: String,
    isLoading: Bool,
    action: @escaping () async -> Void
) -> some View {
    VStack(spacing: 0) {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 0.5)

        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView().tint(.black).scaleEffect(0.8)
                } else {
                    Image(systemName: icon).font(.system(size: 16))
                }
                Text(isLoading ? "PROCESSING..." : title)
                    .font(.custom("Rajdhani-Bold", size: 16))
                    .tracking(2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(isLoading ? Color.potomacYellow.opacity(0.6) : Color.potomacYellow)
            .cornerRadius(12)
        }
        .disabled(isLoading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    .background(Color(hex: "0D0D0D"))
}

// MARK: - Clipboard Helper

private func copyToClipboard(_ text: String) {
    #if os(iOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
    HapticManager.shared.lightImpact()
}

// MARK: - Network Helper

private func performRequest(
    _ method: HTTPMethod,
    endpoint: String,
    body: [String: Any]? = nil
) async throws -> Data {
    let baseURL = URL(string: APIEndpoints.baseURL)!
    let url = baseURL.appendingPathComponent(endpoint)

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let token = KeychainManager.shared.get(.accessToken) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    if let body = body {
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    }

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        let errorMessage = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.detail ?? "Request failed (\(httpResponse.statusCode))"
        throw APIError.clientError(errorMessage)
    }

    return data
}

// MARK: - Previews

#Preview("Optimize") {
    AFLOptimizeView(code: "Buy = Cross(MA(C,20), MA(C,50));\nSell = Cross(MA(C,50), MA(C,20));")
        .preferredColorScheme(.dark)
}

#Preview("Debug") {
    AFLDebugView(
        code: "Buy = Cross(MA(C,20), MA(C,50));\nSell = Cross(MA(C,50), MA(C,20));",
        errorMessage: "Error 10: Syntax error near line 2"
    )
    .preferredColorScheme(.dark)
}

#Preview("Explain") {
    AFLExplainView(code: "Buy = Cross(MA(C,20), MA(C,50));\nSell = Cross(MA(C,50), MA(C,20));")
        .preferredColorScheme(.dark)
}

#Preview("Validate") {
    AFLValidateView(code: "Buy = Cross(MA(C,20), MA(C,50));\nSell = Cross(MA(C,50), MA(C,20));")
        .preferredColorScheme(.dark)
}
