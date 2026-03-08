import SwiftUI

struct AFLGeneratorView: View {
    @State private var viewModel = AFLViewModel()
    @FocusState private var promptFocused: Bool
    @State private var showHistory = false
    @State private var showExplanation = false
    @State private var selectedTemplate: AFLTemplate?
    @State private var templateParameters: [String: Any] = [:]
    @State private var showTemplatePicker = true

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                aflNavBar
                Divider().background(Color.white.opacity(0.07))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Error banner
                        if let errorMessage = viewModel.userFacingError {
                            errorBanner(errorMessage)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }

                        // Template picker section
                        if showTemplatePicker {
                            templateSection
                                .padding(.horizontal, 20)
                                .padding(.top, viewModel.userFacingError == nil ? 16 : 0)
                        }

                        // Prompt input
                        promptSection
                            .padding(.horizontal, 20)
                            .padding(.top, viewModel.userFacingError == nil && !showTemplatePicker ? 20 : 8)

                        // Stats bar when code is ready
                        if !viewModel.generatedCode.isEmpty, let stats = viewModel.aflStats {
                            aflStatsBar(stats)
                                .padding(.horizontal, 20)
                        }

                        // Explanation section
                        if !viewModel.explanation.isEmpty {
                            explanationSection
                                .padding(.horizontal, 20)
                        }

                        // Code output
                        if !viewModel.generatedCode.isEmpty || viewModel.isGenerating {
                            codeSection
                                .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 120)
                    }
                }
            }

            // Generate button
            VStack {
                Spacer()
                generateButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0D0D0D").opacity(0), Color(hex: "0D0D0D")],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: 120).ignoresSafeArea(),
                        alignment: .bottom
                    )
            }
        }
        .onTapGesture {
            promptFocused = false
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    promptFocused = false
                }
                .foregroundColor(.potomacYellow)
            }
        }
        .sheet(isPresented: $showHistory) {
            AFLHistorySheet(viewModel: viewModel) {
                showHistory = false
            }
        }
        .task { await viewModel.loadHistory() }
    }

    // MARK: - Nav Bar
    @ViewBuilder
    private var aflNavBar: some View {
        HStack {
            Button {
                showHistory = true
            } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
            Text("AFL GENERATOR")
                .font(.custom("Rajdhani-Bold", size: 16))
                .foregroundColor(.white)
                .tracking(3)
            Spacer()

            Button {
                viewModel.prompt = ""
                viewModel.generatedCode = ""
                viewModel.explanation = ""
                viewModel.error = nil
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.generatedCode.isEmpty ? .white.opacity(0.2) : .white.opacity(0.5))
            }
            .disabled(viewModel.generatedCode.isEmpty && viewModel.prompt.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Error Banner
    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.red.opacity(0.9))
                .lineLimit(2)
            Spacer()
            Button { viewModel.error = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Template Section
    @ViewBuilder
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STRATEGY TEMPLATES")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                Spacer()

                Button {
                    withAnimation(AnimationProvider.quick) {
                        showTemplatePicker.toggle()
                    }
                } label: {
                    Image(systemName: showTemplatePicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            if showTemplatePicker {
                AFLTemplatePicker(
                    selectedTemplate: $selectedTemplate,
                    onSelect: { template in
                        applyTemplate(template)
                    }
                )

                // Show parameter inputs if template is selected
                if let template = selectedTemplate {
                    templateParameterSection(template)
                }
            }
        }
    }

    // MARK: - Template Parameter Section
    @ViewBuilder
    private func templateParameterSection(_ template: AFLTemplate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARAMETERS")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            ForEach(template.parameters) { param in
                AFLParameterInputView(
                    parameter: param,
                    value: Binding(
                        get: { templateParameters[param.name] ?? param.defaultValue },
                        set: { templateParameters[param.name] = $0 }
                    )
                )
            }

            Button {
                generateFromTemplate(template)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                    Text("Use Template")
                        .font(.custom("Quicksand-SemiBold", size: 13))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.potomacYellow)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    private func applyTemplate(_ template: AFLTemplate) {
        // Initialize with default values
        for param in template.parameters {
            templateParameters[param.name] = param.defaultValue
        }
    }

    private func generateFromTemplate(_ template: AFLTemplate) {
        // Build prompt from template and parameters
        var prompt = template.rawValue + " strategy"

        for (name, value) in templateParameters {
            if let doubleValue = value as? Double {
                prompt += " with \(name) = \(doubleValue)"
            } else if let stringValue = value as? String {
                prompt += " with \(name) = \(stringValue)"
            }
        }

        viewModel.prompt = prompt
        showTemplatePicker = false
    }

    // MARK: - Prompt Section
    @ViewBuilder
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DESCRIBE YOUR STRATEGY")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            ZStack(alignment: .topLeading) {
                if viewModel.prompt.isEmpty {
                    Text("e.g. A 20/50 SMA crossover strategy with RSI filter and ATR-based stop loss...")
                        .font(.custom("Quicksand-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(14)
                }
                TextEditor(text: $viewModel.prompt)
                    .focused($promptFocused)
                    .font(.custom("Quicksand-Regular", size: 14))
                    .foregroundColor(.white)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(10)
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(promptFocused ? Color.potomacYellow : Color.white.opacity(0.08), lineWidth: 1)
            )

            // Quick templates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(aflTemplates, id: \.self) { t in
                        Button { viewModel.prompt = t } label: {
                            Text(t)
                                .font(.custom("Quicksand-Medium", size: 11))
                                .foregroundColor(Color.potomacYellow)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.potomacYellow.opacity(0.1))
                                .cornerRadius(20)
                                .overlay(Capsule().stroke(Color.potomacYellow.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private let aflTemplates = [
        "MA Crossover 20/50",
        "RSI Oversold Bounce",
        "MACD + Signal Line",
        "Bollinger Band Squeeze",
        "ATR Trailing Stop",
        "Volume Breakout"
    ]

    // MARK: - AFL Stats Bar
    @ViewBuilder
    private func aflStatsBar(_ stats: AFLStats) -> some View {
        HStack(spacing: 12) {
            if let score = stats.qualityScore {
                StatPill(label: "Quality", value: "\(score)%", color: score > 70 ? .green : .orange)
            }
            if let lines = stats.lineCount {
                StatPill(label: "Lines", value: "\(lines)", color: Color.potomacTurquoise)
            }
            if stats.hasBuySell == true {
                StatPill(label: "Buy/Sell", value: "✓", color: .green)
            }
            if stats.hasPlot == true {
                StatPill(label: "Plot", value: "✓", color: Color(hex: "A78BFA"))
            }
        }
    }

    // MARK: - Explanation Section
    @ViewBuilder
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation { showExplanation.toggle() }
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundColor(Color.potomacYellow)
                    Text("EXPLANATION")
                        .font(.custom("Quicksand-SemiBold", size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)
                    Spacer()
                    Image(systemName: showExplanation ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .buttonStyle(.plain)

            if showExplanation {
                Text(viewModel.explanation)
                    .font(.custom("Quicksand-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }

    // MARK: - Code Section
    @ViewBuilder
    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("GENERATED CODE")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                Spacer()

                if !viewModel.generatedCode.isEmpty {
                    HStack(spacing: 8) {
                        // Copy button
                        Button { viewModel.copyCode() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.showCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 11))
                                Text(viewModel.showCopied ? "Copied!" : "Copy")
                                    .font(.custom("Quicksand-SemiBold", size: 11))
                            }
                            .foregroundColor(viewModel.showCopied ? .green : Color.potomacYellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.potomacYellow.opacity(0.1))
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)

                        // Share button
                        ShareLink(item: viewModel.generatedCode) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }

            if viewModel.isGenerating && viewModel.generatedCode.isEmpty {
                VStack(spacing: 14) {
                    ProgressView().tint(Color.potomacYellow)
                    Text("Yang is writing your strategy...")
                        .font(.custom("Quicksand-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
            } else if !viewModel.generatedCode.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    AFLCodeView(code: viewModel.generatedCode)
                        .padding(16)
                }
                .background(Color(hex: "0A0A0A"))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
            }
        }
    }

    // MARK: - Generate Button
    @ViewBuilder
    private var generateButton: some View {
        Button {
            promptFocused = false
            Task { await viewModel.generateCode() }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isGenerating {
                    ProgressView().tint(.black).scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles").font(.system(size: 16))
                }
                Text(viewModel.isGenerating ? "GENERATING..." : "GENERATE AFL CODE")
                    .font(.custom("Rajdhani-Bold", size: 16))
                    .tracking(2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(viewModel.prompt.isEmpty ? Color.potomacYellow.opacity(0.5) : Color.potomacYellow)
            .cornerRadius(12)
        }
        .disabled(viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.custom("Quicksand-Regular", size: 10))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.custom("Quicksand-SemiBold", size: 11))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - AFL History Sheet

struct AFLHistorySheet: View {
    let viewModel: AFLViewModel
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("HISTORY")
                        .font(.custom("Rajdhani-Bold", size: 16))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(20)

                Divider().background(Color.white.opacity(0.07))

                if viewModel.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.1))
                        Text("No history yet")
                            .font(.custom("Quicksand-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.history) { item in
                                AFLHistoryRow(item: item) {
                                    viewModel.useHistoryItem(item)
                                    onClose()
                                } onDelete: {
                                    Task { await viewModel.deleteHistoryItem(item) }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }
}

// MARK: - AFL History Row

struct AFLHistoryRow: View {
    let item: AFLHistoryEntry
    let onUse: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Color.potomacTurquoise)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.prompt ?? "Unnamed strategy")
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let date = item.createdAt {
                    Text(date, style: .date)
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onUse) {
                    Text("Use")
                        .font(.custom("Quicksand-SemiBold", size: 11))
                        .foregroundColor(Color.potomacYellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.potomacYellow.opacity(0.1))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.25))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Simple AFL Syntax Highlighter

struct AFLCodeView: View {
    let code: String

    private let keywords: Set<String> = [
        "SetOption", "SetSystem", "SetBacktestMode",
        "Buy", "Sell", "Short", "Cover",
        "MA", "EMA", "RSI", "MACD", "Signal",
        "Cross", "CrossAbove", "CrossBelow",
        "Plot", "PlotShapes", "PlotText",
        "ApplyStop", "Param",
        "if", "else", "for", "while", "return",
        "True", "False", "Null",
        "IIf", "BarCount", "Close", "Open", "High", "Low", "Volume"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(code.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                highlightedLine(line)
            }
        }
    }

    @ViewBuilder
    private func highlightedLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("//") {
            Text(line)
                .font(.custom("FiraCode-Regular", size: 12))
                .foregroundColor(Color(hex: "6A9955"))
        } else if trimmed.hasPrefix("/*") || trimmed.hasSuffix("*/") {
            Text(line)
                .font(.custom("FiraCode-Regular", size: 12))
                .foregroundColor(Color(hex: "6A9955"))
        } else {
            Text(line)
                .font(.custom("FiraCode-Regular", size: 12))
                .foregroundColor(Color(hex: "D4D4D4"))
        }
    }
}
