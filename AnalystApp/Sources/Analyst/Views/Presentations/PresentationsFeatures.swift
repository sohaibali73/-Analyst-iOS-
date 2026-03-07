import SwiftUI

// MARK: - Slide Preview Card

struct SlidePreviewCard: View {
    let slide: PresentationSlide
    let index: Int
    let theme: PresentationTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Slide preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.backgroundColor)
                        .frame(height: 80)
                    
                    VStack(spacing: 4) {
                        Text(slide.title.isEmpty ? "Slide \(index + 1)" : slide.title)
                            .font(.quicksandSemiBold(10))
                            .foregroundColor(theme.textColor)
                            .lineLimit(1)
                        
                        if !slide.bullets.isEmpty {
                            Text("• \(slide.bullets.components(separatedBy: "\n").first ?? "")")
                                .font(.quicksandRegular(8))
                                .foregroundColor(theme.textColor.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    .padding(8)
                }
                
                // Slide number
                Text("Slide \(index + 1)")
                    .font(.quicksandSemiBold(9))
                    .foregroundColor(isSelected ? .potomacYellow : .white.opacity(0.4))
                    .padding(.top, 4)
            }
            .frame(width: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.potomacYellow : Color.clear, lineWidth: 2)
                    .padding(.bottom, 16)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation Theme Extensions

extension PresentationTheme {
    var backgroundColor: Color {
        switch self {
        case .dark: return Color(hex: "1A1A2E")
        case .light: return Color(hex: "F5F5F5")
        case .corporate: return Color(hex: "1B2838")
        case .potomac: return Color(hex: "0D0D0D")
        }
    }
    
    var textColor: Color {
        switch self {
        case .dark: return .white
        case .light: return .black
        case .corporate: return .white
        case .potomac: return .potomacYellow
        }
    }
    
    var accentColor: Color {
        switch self {
        case .dark: return .blue
        case .light: return Color(hex: "2563EB")
        case .corporate: return Color(hex: "3B82F6")
        case .potomac: return .potomacYellow
        }
    }
}

// MARK: - Slide Sorter View

struct SlideSorterView: View {
    @Binding var slides: [PresentationSlide]
    let theme: PresentationTheme
    @State private var selectedIndex: Int?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                            SlidePreviewCard(
                                slide: slide,
                                index: index,
                                theme: theme,
                                isSelected: selectedIndex == index
                            ) {
                                selectedIndex = index
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SLIDE SORTER")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
        }
    }
}

// MARK: - Template Gallery

struct TemplateGalleryView: View {
    let onSelect: (PresentationTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(PresentationTemplate.allCases, id: \.self) { template in
                            TemplateCard(template: template) {
                                onSelect(template)
                                dismiss()
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TEMPLATES")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: PresentationTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(template.color.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: template.icon)
                            .font(.system(size: 20))
                            .foregroundColor(template.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.rawValue)
                            .font(.quicksandSemiBold(14))
                            .foregroundColor(.white)
                        Text(template.description)
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.2))
                }
                
                // Slide count
                Text("\(template.slideCount) slides")
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation Template

enum PresentationTemplate: String, CaseIterable {
    case marketAnalysis = "Market Analysis"
    case companyPitch = "Company Pitch"
    case portfolioReview = "Portfolio Review"
    case strategyOverview = "Strategy Overview"
    case quarterlyReport = "Quarterly Report"
    
    var icon: String {
        switch self {
        case .marketAnalysis: return "chart.line.uptrend.xyaxis"
        case .companyPitch: return "building.2"
        case .portfolioReview: return "chart.pie"
        case .strategyOverview: return "target"
        case .quarterlyReport: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .marketAnalysis: return .potomacYellow
        case .companyPitch: return .chartBlue
        case .portfolioReview: return .chartGreen
        case .strategyOverview: return .potomacTurquoise
        case .quarterlyReport: return .chartOrange
        }
    }
    
    var description: String {
        switch self {
        case .marketAnalysis: return "Technical & fundamental market overview"
        case .companyPitch: return "Investment thesis and company analysis"
        case .portfolioReview: return "Performance review and allocation analysis"
        case .strategyOverview: return "Trading strategy presentation"
        case .quarterlyReport: return "Quarterly performance and outlook"
        }
    }
    
    var slideCount: Int {
        switch self {
        case .marketAnalysis: return 8
        case .companyPitch: return 10
        case .portfolioReview: return 6
        case .strategyOverview: return 7
        case .quarterlyReport: return 9
        }
    }
}

// MARK: - Speaker Notes Editor

struct SpeakerNotesEditor: View {
    @Binding var notes: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                Text("SPEAKER NOTES")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                Spacer()
                Text("\(notes.count) chars")
                    .font(.quicksandRegular(9))
                    .foregroundColor(.white.opacity(0.2))
            }
            
            TextEditor(text: $notes)
                .focused($isFocused)
                .font(.quicksandRegular(12))
                .foregroundColor(.white)
                .frame(minHeight: 60, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.potomacYellow.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - Export Options View

struct PresentationExportOptions: View {
    let onExport: (PresentationExportFormat) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXPORT OPTIONS")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            ForEach(PresentationExportFormat.allCases, id: \.self) { format in
                Button { onExport(format) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: format.icon)
                            .font(.system(size: 16))
                            .foregroundColor(format.color)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(format.rawValue)
                                .font(.quicksandSemiBold(13))
                                .foregroundColor(.white)
                            Text(format.description)
                                .font(.quicksandRegular(10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.2))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Presentation Export Format

enum PresentationExportFormat: String, CaseIterable {
    case pptx = "PowerPoint"
    case pdf = "PDF"
    case images = "Images"
    
    var icon: String {
        switch self {
        case .pptx: return "doc.richtext"
        case .pdf: return "doc.fill"
        case .images: return "photo.on.rectangle"
        }
    }
    
    var color: Color {
        switch self {
        case .pptx: return .chartOrange
        case .pdf: return .chartRed
        case .images: return .chartBlue
        }
    }
    
    var description: String {
        switch self {
        case .pptx: return "Editable PowerPoint file"
        case .pdf: return "Print-ready PDF document"
        case .images: return "Individual slide images"
        }
    }
}