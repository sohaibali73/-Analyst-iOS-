import SwiftUI

// MARK: - Message Actions

/// Actions available for chat messages
enum MessageAction: String, CaseIterable, Identifiable {
    case copy = "Copy"
    case regenerate = "Regenerate"
    case edit = "Edit"
    case delete = "Delete"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .copy: return "doc.on.doc"
        case .regenerate: return "arrow.clockwise"
        case .edit: return "pencil"
        case .delete: return "trash"
        }
    }
    
    var color: Color {
        switch self {
        case .copy: return .white.opacity(0.6)
        case .regenerate: return .potomacYellow
        case .edit: return .chartBlue
        case .delete: return .chartRed
        }
    }
}

// MARK: - Code Block View with Syntax Highlighting

struct CodeBlockView: View {
    let code: String
    let language: String?
    
    @State private var isCopied = false
    @State private var showPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if let lang = language {
                    Text(lang.uppercased())
                        .font(.firaCode(10))
                        .foregroundColor(.potomacYellow.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.potomacYellow.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button {
                    copyCode()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.quicksandSemiBold(10))
                    }
                    .foregroundColor(isCopied ? .green : .white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.firaCode(12))
                    .foregroundColor(.white.opacity(0.85))
                    .textSelection(.enabled)
                    .padding(12)
            }
        }
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func copyCode() {
        ClipboardManager.copy(code)
        HapticManager.shared.success()
        
        withAnimation(AnimationProvider.quick) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(AnimationProvider.quick) {
                isCopied = false
            }
        }
    }
}

// MARK: - Message Search View

struct MessageSearchView: View {
    let messages: [Message]
    let onSelect: (Message) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @FocusState private var isSearchFocused
    
    private var filteredMessages: [Message] {
        if searchText.isEmpty { return messages }
        return messages.filter { 
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0D0D").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.4))
                        
                        TextField("Search messages...", text: $searchText)
                            .focused($isSearchFocused)
                            .font(.quicksandRegular(15))
                            .foregroundColor(.white)
                        
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding()
                    
                    if filteredMessages.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            iconColor: .potomacYellow,
                            title: searchText.isEmpty ? "Search Messages" : "No Results",
                            subtitle: searchText.isEmpty ? "Find messages in this conversation" : "No messages match '\(searchText)'"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredMessages) { message in
                                    MessageSearchResultRow(
                                        message: message,
                                        searchQuery: searchText
                                    ) {
                                        onSelect(message)
                                        dismiss()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.potomacYellow)
                }
            }
            .onAppear { isSearchFocused = true }
        }
    }
}

struct MessageSearchResultRow: View {
    let message: Message
    let searchQuery: String
    let onSelect: () -> Void
    
    private var highlightedContent: AttributedString {
        var result = AttributedString(message.content)
        
        if !searchQuery.isEmpty {
            if let range = result.range(of: searchQuery, options: .caseInsensitive) {
                result[range].backgroundColor = .potomacYellow.opacity(0.3)
                result[range].foregroundColor = .potomacYellow
            }
        }
        
        return result
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: message.role == .user ? "person.fill" : "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(message.role == .user ? .potomacYellow : .potomacTurquoise)
                    
                    Text(message.role == .user ? "You" : "Yang")
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text(message.createdAt, style: .time)
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Text(highlightedContent)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reaction Button

struct MessageReactionButton: View {
    let reaction: MessageReaction
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(reaction.emoji)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.potomacYellow.opacity(0.2) : Color.white.opacity(0.06))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.potomacYellow : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

enum MessageReaction: String, CaseIterable {
    case thumbsUp = "👍"
    case thumbsDown = "👎"
    case helpful = "💡"
    case star = "⭐"
    
    var emoji: String { rawValue }
    
    static let available: [MessageReaction] = [.thumbsUp, .thumbsDown, .helpful, .star]
}

// MARK: - Typing Indicator with Message

struct TypingIndicatorWithMessage: View {
    let message: String
    
    @State private var phase = false
    
    var body: some View {
        HStack(spacing: 8) {
            YangAvatar(size: 24)
            
            HStack(spacing: 8) {
                Text(message)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.6))
                
                typingDots
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .onAppear { phase = true }
    }
    
    @ViewBuilder
    private var typingDots: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.potomacYellow.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(y: phase ? -3 : 0)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.12),
                        value: phase
                    )
            }
        }
    }
}

// MARK: - Message Input with Draft Support

struct EnhancedMessageInput: View {
    @Binding var text: String
    let draft: String?
    let isStreaming: Bool
    let onSend: () -> Void
    let onAttachment: () -> Void
    let onVoice: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Draft indicator
            if let draft = draft, !draft.isEmpty, text.isEmpty {
                draftIndicator(draft)
            }
            
            // Main input
            HStack(alignment: .bottom, spacing: 8) {
                // Attachment button
                Button(action: onAttachment) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                .disabled(isStreaming)
                
                // Text field
                TextField("Message Yang...", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .font(.quicksandRegular(14))
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isFocused ? Color.potomacYellow.opacity(0.25) : Color.clear, lineWidth: 1)
                    )
                    .disabled(isStreaming)
                
                // Send/Voice button
                if isStreaming {
                    ProgressView()
                        .tint(.potomacYellow)
                        .frame(width: 32, height: 32)
                } else if text.isEmpty {
                    Button(action: onVoice) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.3))
                            .frame(width: 32, height: 32)
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(Color.potomacYellow)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "0A0A0A"))
    }
    
    @ViewBuilder
    private func draftIndicator(_ draft: String) -> some View {
        HStack {
            Image(systemName: "doc.text")
                .font(.system(size: 10))
                .foregroundColor(.potomacYellow.opacity(0.6))
            
            Text("Draft: \(draft.prefix(30))...")
                .font(.quicksandRegular(11))
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
            
            Button("Clear") {
                text = ""
            }
            .font(.quicksandSemiBold(11))
            .foregroundColor(.potomacYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.potomacYellow.opacity(0.05))
    }
}

// MARK: - Quick Reply Suggestion

struct QuickReplySuggestion: View {
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.quicksandMedium(12))
                .foregroundColor(.potomacYellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.potomacYellow.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}