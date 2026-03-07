import SwiftUI

struct PresentationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PresentationsViewModel()
    @State private var showShareSheet = false
    @State private var downloadedData: Data?

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 0) {
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

                        // Success banner
                        if viewModel.generatedId != nil && !viewModel.isGenerating {
                            successBanner
                                .padding(.horizontal, 20)
                                .padding(.top, viewModel.error == nil ? 16 : 0)
                        }

                        // Title & Subtitle
                        titleSection
                            .padding(.horizontal, 20)
                            .padding(.top, viewModel.error == nil && viewModel.generatedId == nil ? 20 : 0)

                        // Theme picker
                        themeSection
                            .padding(.horizontal, 20)

                        // Slides
                        slidesSection
                            .padding(.horizontal, 20)

                        // Generate button
                        generateButton
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 120)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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

            Text("PRESENTATIONS")
                .font(.custom("Rajdhani-Bold", size: 16))
                .foregroundColor(.white)
                .tracking(3)

            Spacer()

            Button {
                viewModel.reset()
                HapticManager.shared.lightImpact()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TITLE")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                TextField("e.g. Q4 Investment Thesis", text: $viewModel.title)
                    .font(.custom("Quicksand-Regular", size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("SUBTITLE (OPTIONAL)")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                TextField("e.g. Portfolio Analysis", text: $viewModel.subtitle)
                    .font(.custom("Quicksand-Regular", size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THEME")
                .font(.custom("Quicksand-SemiBold", size: 10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PresentationTheme.allCases) { theme in
                        Button {
                            viewModel.theme = theme
                            HapticManager.shared.selection()
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(themeColor(theme))
                                    .frame(width: 14, height: 14)

                                Text(theme.displayName.uppercased())
                                    .font(.custom("Quicksand-SemiBold", size: 11))
                                    .foregroundColor(viewModel.theme == theme ? .black : .white.opacity(0.6))
                                    .tracking(0.5)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.theme == theme
                                    ? Color.potomacYellow
                                    : Color.white.opacity(0.05)
                            )
                            .cornerRadius(20)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        viewModel.theme == theme ? Color.potomacYellow : Color.white.opacity(0.08),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func themeColor(_ theme: PresentationTheme) -> Color {
        switch theme {
        case .dark: return Color(hex: "1A1A1A")
        case .light: return .white
        case .corporate: return Color(hex: "1E3A5F")
        case .potomac: return Color.potomacYellow
        }
    }

    // MARK: - Slides Section

    private var slidesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SLIDES")
                    .font(.custom("Quicksand-SemiBold", size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)

                Spacer()

                Text("\(viewModel.slides.count) slide\(viewModel.slides.count == 1 ? "" : "s")")
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }

            ForEach(Array(viewModel.slides.enumerated()), id: \.element.id) { index, slide in
                slideEditor(index: index, slide: slide)
            }

            // Add slide button
            Button {
                viewModel.addSlide()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("ADD SLIDE")
                        .font(.custom("Rajdhani-Bold", size: 13))
                        .tracking(1)
                }
                .foregroundColor(Color.potomacYellow)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.potomacYellow.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.potomacYellow.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func slideEditor(index: Int, slide: PresentationSlide) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F472B6").opacity(0.15))
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.custom("Rajdhani-Bold", size: 13))
                            .foregroundColor(Color(hex: "F472B6"))
                    }

                    Text("SLIDE \(index + 1)")
                        .font(.custom("Quicksand-SemiBold", size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.5)
                }

                Spacer()

                if viewModel.slides.count > 1 {
                    Button {
                        viewModel.removeSlide(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.6))
                    }
                }
            }

            // Slide title
            TextField("Slide title", text: Binding(
                get: { viewModel.slides[safe: index]?.title ?? "" },
                set: { if viewModel.slides.indices.contains(index) { viewModel.slides[index].title = $0 } }
            ))
            .font(.custom("Quicksand-Regular", size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)

            // Bullets
            VStack(alignment: .leading, spacing: 4) {
                Text("Bullet points (one per line)")
                    .font(.custom("Quicksand-Regular", size: 10))
                    .foregroundColor(.white.opacity(0.3))

                TextEditor(text: Binding(
                    get: { viewModel.slides[safe: index]?.bullets ?? "" },
                    set: { if viewModel.slides.indices.contains(index) { viewModel.slides[index].bullets = $0 } }
                ))
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60, maxHeight: 100)
                .padding(10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }

            // Speaker notes
            VStack(alignment: .leading, spacing: 4) {
                Text("Speaker notes (optional)")
                    .font(.custom("Quicksand-Regular", size: 10))
                    .foregroundColor(.white.opacity(0.3))

                TextField("Notes for this slide...", text: Binding(
                    get: { viewModel.slides[safe: index]?.notes ?? "" },
                    set: { if viewModel.slides.indices.contains(index) { viewModel.slides[index].notes = $0 } }
                ))
                .font(.custom("Quicksand-Regular", size: 13))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task { await viewModel.generate() }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isGenerating {
                    ProgressView().tint(.black).scaleEffect(0.85)
                } else {
                    Image(systemName: "doc.badge.gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(viewModel.isGenerating ? "GENERATING..." : "GENERATE PRESENTATION")
                    .font(.custom("Rajdhani-Bold", size: 17))
                    .tracking(2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating
                    ? Color.potomacYellow.opacity(0.5)
                    : Color.potomacYellow
            )
            .cornerRadius(12)
        }
        .disabled(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
        .buttonStyle(.plain)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "22C55E").opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "22C55E"))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Presentation Generated!")
                        .font(.custom("Quicksand-SemiBold", size: 14))
                        .foregroundColor(.white)
                    Text("Your PPTX is ready to download")
                        .font(.custom("Quicksand-Regular", size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()
            }

            Button {
                Task {
                    if let data = await viewModel.download() {
                        downloadedData = data
                        showShareSheet = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 16))
                    Text("DOWNLOAD PPTX")
                        .font(.custom("Rajdhani-Bold", size: 14))
                        .tracking(1)
                }
                .foregroundColor(Color.potomacYellow)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.potomacYellow.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.potomacYellow.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(hex: "22C55E").opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "22C55E").opacity(0.2), lineWidth: 1)
        )
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

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
