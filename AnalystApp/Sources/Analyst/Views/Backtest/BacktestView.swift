import SwiftUI
import UniformTypeIdentifiers

struct BacktestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BacktestViewModel()
    @State private var showFilePicker = false
    @State private var showDetail = false

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                navBar
                Divider().background(Color.white.opacity(0.07))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Error banner
                        if let error = viewModel.error {
                            errorBanner(error)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }

                        // Upload section
                        uploadSection
                            .padding(.horizontal, 20)
                            .padding(.top, viewModel.error == nil ? 20 : 0)

                        // Upload progress
                        if viewModel.isUploading {
                            uploadProgressSection
                                .padding(.horizontal, 20)
                        }

                        // Selected result detail
                        if let result = viewModel.selectedResult {
                            resultDetailSection(result)
                                .padding(.horizontal, 20)
                        }

                        // Results list
                        if !viewModel.backtestResults.isEmpty {
                            resultsListSection
                                .padding(.horizontal, 20)
                        } else if !viewModel.isLoading && viewModel.selectedResult == nil {
                            emptyState
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                        }

                        // Loading
                        if viewModel.isLoading && viewModel.backtestResults.isEmpty {
                            ProgressView()
                                .tint(Color.potomacYellow)
                                .padding(.top, 40)
                        }

                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText, .json, UTType(filenameExtension: "csv") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    Task {
                        await viewModel.uploadBacktest(data: data, filename: url.lastPathComponent, strategyId: nil)
                    }
                }
            case .failure(let error):
                viewModel.error = error.localizedDescription
            }
        }
        .task {
            await viewModel.loadBacktests()
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                HapticManager.shared.lightImpact()
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Home")
                        .font(.custom("Quicksand-SemiBold", size: 14))
                }
                .foregroundColor(Color.potomacYellow)
            }

            Spacer()

            Text("BACKTEST")
                .font(.custom("Rajdhani-Bold", size: 16))
                .foregroundColor(.white)
                .tracking(3)

            Spacer()

            // Balance the back button width
            Color.clear.frame(width: 60, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        Button {
            HapticManager.shared.lightImpact()
            showFilePicker = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "34D399").opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "34D399"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("UPLOAD BACKTEST RESULTS")
                        .font(.custom("Rajdhani-Bold", size: 15))
                        .foregroundColor(.white)
                        .tracking(1)
                    Text("CSV or TXT from AmiBroker")
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "34D399").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isUploading)
    }

    // MARK: - Upload Progress

    private var uploadProgressSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Uploading & Analyzing...")
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(Int(viewModel.uploadProgress * 100))%")
                    .font(.custom("Rajdhani-Bold", size: 16))
                    .foregroundColor(Color.potomacYellow)
            }

            ProgressView(value: viewModel.uploadProgress)
                .progressViewStyle(.linear)
                .tint(Color.potomacYellow)

            if viewModel.uploadProgress > 0.5 {
                Text("AI is analyzing your results...")
                    .font(.custom("Quicksand-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.potomacYellow.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Result Detail

    @ViewBuilder
    private func resultDetailSection(_ result: BacktestResult) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ANALYSIS RESULTS")
                        .font(.custom("Rajdhani-Bold", size: 16))
                        .foregroundColor(.white)
                        .tracking(1.5)

                    if let filename = result.filename {
                        Text(filename)
                            .font(.custom("Quicksand-Regular", size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                if let date = result.createdAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.custom("Quicksand-Regular", size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            // Metrics Grid
            if let metrics = result.metrics {
                MetricsGridView(metrics: metrics)
            }

            // AI Analysis
            if let analysis = result.aiAnalysis, !analysis.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13))
                            .foregroundColor(Color.potomacYellow)
                        Text("AI ANALYSIS")
                            .font(.custom("Quicksand-SemiBold", size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1.5)
                    }

                    Text(analysis)
                        .font(.custom("Quicksand-Regular", size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(3)
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.potomacYellow.opacity(0.12), lineWidth: 1)
                )
            }

            // Recommendations
            if let recs = result.recommendations, !recs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "F97316"))
                        Text("RECOMMENDATIONS")
                            .font(.custom("Quicksand-SemiBold", size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1.5)
                    }

                    ForEach(recs) { rec in
                        recommendationRow(rec)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "F97316").opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private func recommendationRow(_ rec: BacktestRecommendation) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(priorityColor(rec.priority).opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(priorityColor(rec.priority))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(rec.title)
                    .font(.custom("Quicksand-SemiBold", size: 13))
                    .foregroundColor(.white)

                if let desc = rec.description {
                    Text(desc)
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .lineSpacing(2)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }

    private func priorityColor(_ priority: String?) -> Color {
        switch priority?.lowercased() {
        case "high": return Color(hex: "DC2626")
        case "medium": return Color(hex: "F97316")
        default: return Color(hex: "22C55E")
        }
    }

    // MARK: - Results List

    private var resultsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.potomacYellow)
                Text("PREVIOUS BACKTESTS")
                    .font(.custom("Rajdhani-Bold", size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                Spacer()
            }

            ForEach(viewModel.backtestResults) { result in
                Button {
                    HapticManager.shared.lightImpact()
                    viewModel.selectedResult = result
                } label: {
                    backtestRow(result)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteBacktest(result) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func backtestRow(_ result: BacktestResult) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "34D399").opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "34D399"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.filename ?? "Backtest Result")
                    .font(.custom("Quicksand-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let cagr = result.metrics?.cagr {
                        Text("CAGR: \(String(format: "%.1f%%", cagr))")
                            .font(.custom("Quicksand-Regular", size: 11))
                            .foregroundColor(cagr >= 0 ? Color(hex: "22C55E") : Color(hex: "DC2626"))
                    }
                    if let sharpe = result.metrics?.sharpeRatio {
                        Text("Sharpe: \(String(format: "%.2f", sharpe))")
                            .font(.custom("Quicksand-Regular", size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            if let date = result.createdAt {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.15))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.selectedResult?.id == result.id ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(viewModel.selectedResult?.id == result.id ? Color(hex: "34D399").opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "34D399").opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "34D399").opacity(0.5))
            }

            VStack(spacing: 6) {
                Text("Backtest Analysis")
                    .font(.custom("Rajdhani-Bold", size: 20))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Upload your AmiBroker backtest results\nto get AI-powered analysis & recommendations")
                    .font(.custom("Quicksand-Regular", size: 13))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 40)
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
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

