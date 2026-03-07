import SwiftUI

// MARK: - Document Detail View

struct DocumentDetailView: View {
    let document: KnowledgeDocument
    @State private var showChunkExplorer = false
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Document header
                        documentHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Metadata card
                        metadataCard
                            .padding(.horizontal, 20)
                        
                        // Summary
                        if let summary = document.summary, !summary.isEmpty {
                            summarySection(summary)
                                .padding(.horizontal, 20)
                        }
                        
                        // Chunk preview
                        if let chunks = document.chunkCount, chunks > 0 {
                            chunkPreviewSection
                                .padding(.horizontal, 20)
                        }
                        
                        // Actions
                        actionButtons
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("DOCUMENT DETAILS")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
            .sheet(isPresented: $showChunkExplorer) {
                ChunkExplorerView(documentId: document.id)
            }
            .confirmationDialog("Delete Document", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    // Delete action
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this document? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header
    @ViewBuilder
    private var documentHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(document.iconColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: document.iconName)
                    .font(.system(size: 26))
                    .foregroundColor(document.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName)
                    .font(.quicksandSemiBold(16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(document.fileExtension.uppercased())
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(document.iconColor)
                    .tracking(1)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Metadata Card
    @ViewBuilder
    private var metadataCard: some View {
        HStack(spacing: 16) {
            if let size = document.fileSize {
                VStack(spacing: 4) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                    Text(document.formattedSize)
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.white)
                    Text("Size")
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
            }
            
            if let chunks = document.chunkCount {
                VStack(spacing: 4) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(chunks)")
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.potomacYellow)
                    Text("Chunks")
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
            }
            
            VStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                Text(document.formattedDate)
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(.white)
                Text("Added")
                    .font(.quicksandRegular(10))
                    .foregroundColor(.white.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
    
    // MARK: - Summary Section
    @ViewBuilder
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12))
                    .foregroundColor(.potomacYellow)
                Text("SUMMARY")
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.5)
            }
            
            Text(summary)
                .font(.quicksandRegular(13))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    // MARK: - Chunk Preview
    @ViewBuilder
    private var chunkPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 12))
                        .foregroundColor(.potomacTurquoise)
                    Text("CONTENT CHUNKS")
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1.5)
                }
                
                Spacer()
                
                Button("View All") {
                    showChunkExplorer = true
                }
                .font(.quicksandSemiBold(11))
                .foregroundColor(.potomacYellow)
            }
            
            // Preview chunks
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 10) {
                        Text("#\(i + 1)")
                            .font(.quicksandSemiBold(10))
                            .foregroundColor(.potomacTurquoise)
                            .frame(width: 28)
                        
                        Text("Chunk content preview...")
                            .font(.quicksandRegular(12))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                showChunkExplorer = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                    Text("Explore Content")
                        .font(.quicksandSemiBold(13))
                }
                .foregroundColor(.potomacYellow)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.potomacYellow.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    Text("Delete Document")
                        .font(.quicksandSemiBold(13))
                }
                .foregroundColor(.chartRed)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.chartRed.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Chunk Explorer View

struct ChunkExplorerView: View {
    let documentId: String
    @State private var chunks: [DocumentChunk] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var filteredChunks: [DocumentChunk] {
        if searchText.isEmpty { return chunks }
        return chunks.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.3))
                        TextField("Search chunks...", text: $searchText)
                            .font(.quicksandRegular(14))
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.potomacYellow)
                        Spacer()
                    } else if filteredChunks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.15))
                            Text("No chunks found")
                                .font(.quicksandRegular(14))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredChunks) { chunk in
                                    ChunkRowView(chunk: chunk)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CONTENT EXPLORER")
                        .font(.rajdhaniBold(14))
                        .foregroundColor(.white)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
            .task {
                // Load chunks
                try? await Task.sleep(nanoseconds: 500_000_000)
                // Mock data for now
                chunks = (0..<10).map { i in
                    DocumentChunk(
                        id: "\(documentId)-\(i)",
                        content: "This is chunk #\(i + 1) content from the document. It contains relevant information that has been indexed for semantic search.",
                        index: i
                    )
                }
                isLoading = false
            }
        }
    }
}

// MARK: - Document Chunk Model

struct DocumentChunk: Identifiable, Codable {
    let id: String
    let content: String
    let index: Int
}

// MARK: - Chunk Row View

struct ChunkRowView: View {
    let chunk: DocumentChunk
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.potomacTurquoise.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Text("#\(chunk.index + 1)")
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(.potomacTurquoise)
                }
                
                Text("\(chunk.content.prefix(50))...")
                    .font(.quicksandRegular(12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                
                Spacer()
                
                Button {
                    withAnimation(AnimationProvider.quick) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            if isExpanded {
                Text(chunk.content)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
                    .padding(.leading, 36)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

// MARK: - Knowledge Stats View

struct KnowledgeStatsView: View {
    let stats: BrainStats
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KNOWLEDGE BASE STATS")
                .font(.quicksandSemiBold(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)
            
            // Main stats
            HStack(spacing: 12) {
                StatGauge(
                    title: "Documents",
                    value: stats.totalDocuments,
                    color: .potomacYellow,
                    animate: animateChart
                )
                
                StatGauge(
                    title: "Chunks",
                    value: stats.totalChunks,
                    color: .potomacTurquoise,
                    animate: animateChart
                )
                
                StatGauge(
                    title: "Learnings",
                    value: stats.totalLearnings ?? 0,
                    color: .chartGreen,
                    animate: animateChart
                )
            }
            
            // Category breakdown
            if !stats.categories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("By Category")
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.white.opacity(0.5))
                    
                    ForEach(stats.categories.sorted(by: { $0.value > $1.value }), id: \.key) { cat, count in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(categoryColor(cat))
                                .frame(width: 8, height: 8)
                            
                            Text(cat.capitalized)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.quicksandSemiBold(12))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.02))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateChart = true
            }
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "strategy": return .potomacYellow
        case "indicator": return .potomacTurquoise
        case "research": return .chartBlue
        case "notes": return .chartOrange
        default: return .white.opacity(0.5)
        }
    }
}

// MARK: - Stat Gauge

struct StatGauge: View {
    let title: String
    let value: Int
    let color: Color
    var animate: Bool = true
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.quicksandRegular(10))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.5)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                
                Circle()
                    .trim(from: 0, to: animate ? min(1.0, Double(value) / 100.0) : 0)
                    .stroke(
                        color.gradient,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)")
                    .font(.quicksandSemiBold(16))
                    .foregroundColor(color)
            }
            .frame(width: 60, height: 60)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Upload View

struct QuickUploadView: View {
    let onUpload: (Data, String, String) -> Void
    @State private var draggedOver = false
    @State private var showFilePicker = false
    
    var body: some View {
        Button {
            showFilePicker = true
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.potomacYellow.opacity(draggedOver ? 0.2 : 0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.potomacYellow)
                }
                
                Text("Drop files here or tap to upload")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.4))
                
                Text("PDF, TXT, CSV, JSON, MD")
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        draggedOver ? Color.potomacYellow : Color.white.opacity(0.1),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
            )
            .background(draggedOver ? Color.potomacYellow.opacity(0.05) : Color.clear)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .onDrop(of: [.data], isTargeted: $draggedOver) { providers in
            // Handle drop
            return true
        }
    }
}

// MARK: - Document Search Result Row

struct DocumentSearchResultRow: View {
    let document: KnowledgeDocument
    let searchQuery: String
    let onTap: () -> Void
    
    private var highlightedTitle: AttributedString {
        var result = AttributedString(document.displayName)
        if !searchQuery.isEmpty {
            if let range = result.range(of: searchQuery, options: .caseInsensitive) {
                result[range].backgroundColor = .potomacYellow.opacity(0.3)
                result[range].foregroundColor = .potomacYellow
            }
        }
        return result
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(document.iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: document.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(document.iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(highlightedTitle)
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let summary = document.summary {
                        Text(summary)
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
