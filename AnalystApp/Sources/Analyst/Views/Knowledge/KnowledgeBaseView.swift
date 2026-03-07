import SwiftUI

// MARK: - Knowledge Base View

struct KnowledgeBaseView: View {
    @State private var viewModel = KnowledgeViewModel()
    @State private var searchText = ""
    @State private var showUploadSheet = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showDocumentPicker = false
    @State private var selectedDocument: KnowledgeDocument?
    @State private var selectedCategory: DocumentCategory?
    @State private var showCategoryPicker = false
    
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                knowledgeHeader
                
                // Search bar
                searchBar
                
                // Category filters
                categoryFilters
                
                Divider()
                    .background(Color.white.opacity(0.07))
                    .padding(.vertical, 12)
                
                // Content
                if viewModel.isLoading && viewModel.documents.isEmpty {
                    loadingState
                } else if filteredDocuments.isEmpty {
                    emptyState
                } else {
                    documentsList
                }
            }
            
            // Upload progress overlay
            if isUploading {
                uploadProgressOverlay
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .sheet(isPresented: $showUploadSheet) {
            DocumentUploadSheet(viewModel: viewModel) { progress in
                isUploading = true
                uploadProgress = progress
            } onComplete: {
                isUploading = false
                uploadProgress = 0
            }
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentDetailView(document: doc)
        }
        .task {
            await viewModel.loadDocuments()
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var knowledgeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("KNOWLEDGE BASE")
                    .font(.rajdhaniBold(16))
                    .foregroundColor(.white)
                    .tracking(3)
                
                Text("\(viewModel.documents.count) documents")
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.35))
            }
            
            Spacer()
            
            // Upload button
            Button {
                showUploadSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Upload")
                        .font(.quicksandSemiBold(12))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.potomacYellow)
                .clipShape(Capsule())
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Search Bar
    
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
            
            TextField("Search documents...", text: $searchText)
                .font(.quicksandRegular(14))
                .foregroundColor(.white)
                .focused($searchFocused)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(searchFocused ? Color.potomacYellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Category Filters
    
    @ViewBuilder
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    count: viewModel.documents.count,
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                    HapticManager.shared.lightImpact()
                }
                
                ForEach(DocumentCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        count: viewModel.documents.filter { $0.documentCategory == category }.count,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        HapticManager.shared.lightImpact()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
    
    // MARK: - Loading State
    
    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonDocumentCard()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.potomacYellow.opacity(0.6))
            }
            
            VStack(spacing: 6) {
                Text(searchText.isEmpty ? "No documents yet" : "No results found")
                    .font(.rajdhaniBold(18))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Text(searchText.isEmpty ? "Upload documents to search and query them with AI" : "Try a different search term")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button {
                    showUploadSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 14))
                        Text("Upload Document")
                            .font(.quicksandSemiBold(14))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.potomacYellow)
                    .clipShape(Capsule())
                }
                .buttonStyle(.pressable)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Documents List
    
    @ViewBuilder
    private var documentsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(Array(filteredDocuments.enumerated()), id: \.element.id) { index, doc in
                    PremiumDocumentCard(
                        document: doc,
                        searchQuery: searchText
                    ) {
                        selectedDocument = doc
                    }
                    .staggeredEntry(index: index, totalCount: filteredDocuments.count)
                }
                
                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .refreshable {
            await viewModel.loadDocuments()
        }
    }
    
    // MARK: - Upload Progress Overlay
    
    @ViewBuilder
    private var uploadProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: uploadProgress)
                        .stroke(Color.potomacYellow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: uploadProgress)
                    
                    Text("\(Int(uploadProgress * 100))%")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.white)
                }
                
                Text("Uploading...")
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(32)
            .background(Color(hex: "1A1A1A"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredDocuments: [KnowledgeDocument] {
        var docs = viewModel.documents
        
        // Filter by category
        if let category = selectedCategory {
            docs = docs.filter { $0.documentCategory == category }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            docs = docs.filter { doc in
                doc.displayName.localizedCaseInsensitiveContains(searchText) ||
                (doc.summary?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return docs
    }
}

// MARK: - Document Category

enum DocumentCategory: String, CaseIterable {
    case earnings = "Earnings"
    case research = "Research"
    case strategy = "Strategy"
    case news = "News"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .earnings: return "chart.bar.fill"
        case .research: return "doc.text.fill"
        case .strategy: return "function"
        case .news: return "newspaper.fill"
        case .other: return "folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .earnings: return .potomacYellow
        case .research: return .potomacTurquoise
        case .strategy: return Color(hex: "A78BFA")
        case .news: return Color(hex: "60A5FA")
        case .other: return .white.opacity(0.5)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.4))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.black.opacity(0.15) : Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.potomacYellow : Color.white.opacity(isPressed ? 0.08 : 0.05))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(AnimationProvider.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Premium Document Card

struct PremiumDocumentCard: View {
    let document: KnowledgeDocument
    let searchQuery: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Document icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [document.documentCategory.color.opacity(0.2), document.documentCategory.color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(document.documentCategory.color.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    Image(systemName: document.documentCategory.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(document.documentCategory.color)
                }
                
                // Document info
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.displayName)
                        .font(.quicksandSemiBold(14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Category badge
                        Text(document.documentCategory.rawValue)
                            .font(.quicksandSemiBold(9))
                            .foregroundColor(document.documentCategory.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(document.documentCategory.color.opacity(0.1))
                            .clipShape(Capsule())
                        
                        // File size
                        if let size = document.fileSize {
                            Text(formatFileSize(size))
                                .font(.quicksandRegular(10))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        
                        // Date added
                        if let date = document.createdAt {
                            Text(formatDate(date))
                                .font(.quicksandRegular(10))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    
                    // Summary preview
                    if let summary = document.summary, !summary.isEmpty {
                        Text(String(summary.prefix(80)) + "...")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.35))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Action button
                Button {
                    // Search in this document
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AnimationProvider.quick, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Skeleton Document Card

struct SkeletonDocumentCard: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonView(cornerRadius: 10, height: 48, width: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(cornerRadius: 4, height: 14, width: 180)
                SkeletonView(cornerRadius: 4, height: 10, width: 100)
                SkeletonView(cornerRadius: 4, height: 10, width: 150)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Document Upload Sheet

struct DocumentUploadSheet: View {
    let viewModel: KnowledgeViewModel
    let onProgress: (Double) -> Void
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: DocumentCategory = .other
    @State private var isUploading = false
    
    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("UPLOAD DOCUMENT")
                        .font(.rajdhaniBold(16))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(20)
                
                Divider().background(Color.white.opacity(0.07))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Drop zone
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                    )
                                    .foregroundColor(Color.potomacYellow.opacity(0.3))
                                    .frame(height: 160)
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "cloud.upload.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.potomacYellow.opacity(0.5))
                                    
                                    Text("Drop file here or tap to browse")
                                        .font(.quicksandRegular(13))
                                        .foregroundColor(.white.opacity(0.4))
                                    
                                    Text("PDF, TXT, DOC, DOCX")
                                        .font(.quicksandRegular(11))
                                        .foregroundColor(.white.opacity(0.25))
                                }
                            }
                            .onTapGesture {
                                // Open file picker
                            }
                        }
                        
                        // Category selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CATEGORY")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(1.5)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(DocumentCategory.allCases, id: \.self) { category in
                                    Button {
                                        selectedCategory = category
                                        HapticManager.shared.lightImpact()
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 16))
                                            Text(category.rawValue)
                                                .font(.quicksandSemiBold(11))
                                        }
                                        .foregroundColor(selectedCategory == category ? .black : .white.opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedCategory == category ? category.color : Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        
                        // Info
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "60A5FA"))
                            Text("Uploaded documents are processed and indexed for AI-powered search and Q&A.")
                                .font(.quicksandRegular(12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(14)
                        .background(Color(hex: "60A5FA").opacity(0.08))
                        .cornerRadius(10)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
    }
}

// MARK: - Document Metadata Item

struct DocumentMetadataItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Text(value)
                .font(.quicksandSemiBold(13))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

// MARK: - KnowledgeDocument Model Extension

extension KnowledgeDocument {
    /// Maps the raw `category` string to the `DocumentCategory` enum
    var documentCategory: DocumentCategory {
        DocumentCategory(rawValue: self.category ?? "Other") ?? .other
    }
}

// MARK: - Preview

#Preview {
    KnowledgeBaseView()
        .preferredColorScheme(.dark)
}