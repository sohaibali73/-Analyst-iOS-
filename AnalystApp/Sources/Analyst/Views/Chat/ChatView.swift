import SwiftUI

// MARK: - Chat View

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    @State private var showSidebar = false
    @State private var showAttachmentPicker = false
    @State private var pendingAttachments: [AttachmentItem] = []
    @FocusState private var inputFocused: Bool
    @State private var showStopConfirmation = false
    @State private var showSearch = false
    @State private var selectedReaction: MessageReaction?
    @State private var draftText: String = ""
    @State private var showVoiceMode = false
    @State private var showScrollToBottom = false
    
    // Message reactions storage (in production, this would be persisted)
    @State private var messageReactions: [String: MessageReactionType] = [:]

    var body: some View {
        ZStack {
            Color(hex: "0A0A0A").ignoresSafeArea()

            VStack(spacing: 0) {
                chatHeader
                messagesList
                if !pendingAttachments.isEmpty { attachmentPreview }
                inputArea
            }

            // Scroll to bottom button
            if showScrollToBottom {
                scrollToBottomButton
            }

            // Left-side drawer for conversations
            if showSidebar {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation(.easeOut(duration: 0.25)) { showSidebar = false } }

                HStack(spacing: 0) {
                    ConversationSidebar(viewModel: viewModel) {
                        withAnimation(.easeOut(duration: 0.25)) { showSidebar = false }
                    }
                    .frame(width: 300)
                    .transition(.move(edge: .leading))

                    Spacer()
                }
                .transition(.opacity)
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        #if os(iOS) || os(visionOS)
        .sheet(isPresented: $showAttachmentPicker) {
            FileAttachmentPicker(
                onAttach: { items in
                    pendingAttachments.append(contentsOf: items)
                    showAttachmentPicker = false
                },
                onDismiss: { showAttachmentPicker = false }
            )
        }
        .fullScreenCover(isPresented: $showVoiceMode) {
            VoiceConversationView()
                .environment(viewModel)
        }
        #endif
        .sheet(isPresented: $showSearch) {
            MessageSearchView(
                messages: viewModel.messages,
                onSelect: { message in
                    // Scroll to selected message
                    showSearch = false
                }
            )
        }
        .task {
            if viewModel.currentConversation == nil {
                await viewModel.loadOrCreateConversation()
            }
        }
        .animation(.easeOut(duration: 0.25), value: showSidebar)
    }

    // MARK: - Header

    @ViewBuilder
    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button {
                inputFocused = false
                Task { await viewModel.loadConversations() }
                withAnimation(.easeOut(duration: 0.25)) { showSidebar = true }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.pressable)

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.currentConversation?.displayTitle ?? "New Chat")
                    .font(.rajdhaniBold(15))
                    .foregroundColor(.white.opacity(0.8))
                    .tracking(1)
                    .lineLimit(1)
                
                if viewModel.isStreaming {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.potomacYellow)
                            .frame(width: 6, height: 6)
                        Text("Yang is typing...")
                            .font(.quicksandRegular(10))
                            .foregroundColor(.potomacYellow.opacity(0.6))
                    }
                    .transition(.opacity)
                }
            }

            Spacer()

            // Voice mode button
            Button {
                inputFocused = false
                showVoiceMode = true
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.potomacTurquoise)
                    .frame(width: 34, height: 34)
                    .background(Color.potomacTurquoise.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.pressable)

            // Search button
            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.pressable)

            Button {
                inputFocused = false
                Task { await viewModel.createNewConversation() }
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.potomacYellow)
                    .frame(width: 34, height: 34)
                    .background(Color.potomacYellow.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.pressable)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)

        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
    }

    // MARK: - Messages List

    @ViewBuilder
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.messages.isEmpty && !viewModel.isLoadingHistory {
                        welcomeContent.padding(.top, 40)
                    } else {
                        ForEach(viewModel.messages) { message in
                            EnhancedChatMessageRow(
                                message: message,
                                reaction: messageReactions[message.id],
                                onReaction: { reaction in
                                    withAnimation(AnimationProvider.bouncy) {
                                        messageReactions[message.id] = reaction
                                    }
                                    HapticManager.shared.lightImpact()
                                },
                                onCopy: {
                                    ClipboardManager.copy(message.content)
                                    ToastManager.shared.success("Copied to clipboard")
                                },
                                onShare: {
                                    // Share the message
                                },
                                onReadAloud: {
                                    // Trigger voice mode for this message
                                }
                            )
                            .id(message.id)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                        }
                    }

                    if viewModel.isStreaming && viewModel.messages.last?.role != .assistant {
                        EnhancedTypingRow()
                            .id("typing")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                    }

                    Color.clear.frame(height: 8).id("bottom")
                }
                .padding(.top, 6)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollClipDisabled()
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isStreaming) { _, streaming in
                if streaming { scrollToBottom(proxy) }
            }
            .onAppear {
                // Monitor scroll position
            }
        }
    }
    
    // MARK: - Scroll to Bottom Button
    
    @ViewBuilder
    private var scrollToBottomButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    // Scroll to bottom action
                    HapticManager.shared.lightImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Jump to latest")
                            .font(.quicksandSemiBold(11))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.potomacYellow)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.pressable)
                .padding(.trailing, 16)
                .padding(.bottom, 100)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(AnimationProvider.bouncy, value: showScrollToBottom)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    // MARK: - Welcome Content

    @ViewBuilder
    private var welcomeContent: some View {
        VStack(spacing: 24) {
            // Animated avatar
            ZStack {
                Circle()
                    .fill(Color.potomacYellow.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .pulseAnimation()
                
                Circle()
                    .fill(Color.potomacYellow.opacity(0.12))
                    .frame(width: 60, height: 60)
                
                Image("potomac-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }

            VStack(spacing: 6) {
                Text("How can I help?")
                    .font(.rajdhaniBold(22))
                    .foregroundColor(.white)
                Text("Markets, AFL code, analysis & more.")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.3))
            }

            VStack(spacing: 8) {
                ForEach(Array(quickPrompts.enumerated()), id: \.element) { index, prompt in
                    QuickPromptButton(prompt: prompt, icon: promptIcon(prompt)) {
                        inputText = prompt
                        sendMessage()
                    }
                    .staggeredEntry(index: index, totalCount: quickPrompts.count, baseDelay: 0.1)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 24)
    }

    private let quickPrompts = [
        "What's the current market outlook?",
        "Help me write an AFL strategy",
        "Analyze my portfolio risk",
        "Get me the latest AAPL stock data"
    ]

    private func promptIcon(_ prompt: String) -> String {
        if prompt.contains("market") { return "chart.line.uptrend.xyaxis" }
        if prompt.contains("AFL") { return "chevron.left.forwardslash.chevron.right" }
        if prompt.contains("portfolio") { return "chart.pie" }
        return "magnifyingglass"
    }

    // MARK: - Attachment Preview

    @ViewBuilder
    private var attachmentPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(pendingAttachments) { item in
                    HStack(spacing: 5) {
                        Image(systemName: item.iconName)
                            .font(.system(size: 9))
                            .foregroundColor(item.iconColor)
                        Text(item.name)
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                        Button {
                            pendingAttachments.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.2))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
        }
    }

    // MARK: - Input Area

    @ViewBuilder
    private var inputArea: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)

            // Stop generation button (shown during streaming)
            if viewModel.isStreaming {
                Button {
                    HapticManager.shared.mediumImpact()
                    viewModel.stopStreaming()
                    ToastManager.shared.info("Generation stopped")
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Stop Generating")
                            .font(.quicksandSemiBold(13))
                    }
                    .foregroundColor(.chartRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.chartRed.opacity(0.1))
                    .clipShape(Capsule())
                }
                .padding(.vertical, 8)
                .transition(.scale.combined(with: .opacity))
            }

            HStack(alignment: .bottom, spacing: 8) {
                // Attachment button
                Button {
                    inputFocused = false
                    showAttachmentPicker = true
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(width: 32, height: 32)
                }
                .disabled(viewModel.isStreaming)
                .buttonStyle(.pressable)

                // Compact text field
                TextField("Message Yang...", text: $inputText, axis: .vertical)
                    .focused($inputFocused)
                    .font(.quicksandRegular(14))
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(inputFocused ? Color.potomacYellow.opacity(0.25) : Color.clear, lineWidth: 1)
                    )
                    .disabled(viewModel.isStreaming)

                // Send button or typing indicator
                if viewModel.isStreaming {
                    ProgressView()
                        .tint(.potomacYellow)
                        .frame(width: 32, height: 32)
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(canSend ? .black : .white.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .background(canSend ? Color.potomacYellow : Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .disabled(!canSend)
                    .buttonStyle(.pressable)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "0A0A0A"))
        .animation(AnimationProvider.quick, value: viewModel.isStreaming)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isStreaming
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        inputFocused = false
        let attachments = pendingAttachments
        pendingAttachments = []
        Task {
            if !attachments.isEmpty {
                await viewModel.sendMessageWithAttachments(text, attachments: attachments)
            } else {
                await viewModel.sendMessage(text)
            }
        }
    }
}

// MARK: - Quick Prompt Button

struct QuickPromptButton: View {
    let prompt: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.potomacYellow.opacity(0.08))
                        .frame(width: 26, height: 26)
                    
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.potomacYellow.opacity(0.6))
                }
                
                Text(prompt)
                    .font(.quicksandMedium(13))
                    .foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(isPressed ? 0.06 : 0.03))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.04), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AnimationProvider.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Pulse Animation Modifier

struct PulseAnimationModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimationModifier())
    }
}

// MARK: - Yang Avatar

struct YangAvatar: View {
    var size: CGFloat = 32
    var iconSize: CGFloat = 13
    
    var body: some View {
        Image("potomac-icon")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }
}

// MARK: - Message Reaction Type

enum MessageReactionType: String, CaseIterable {
    case thumbsUp = "👍"
    case heart = "❤️"
    case fire = "🔥"
    case star = "⭐️"
    
    var emoji: String { rawValue }
}

// MARK: - Enhanced Chat Message Row

struct EnhancedChatMessageRow: View {
    let message: Message
    let reaction: MessageReactionType?
    let onReaction: (MessageReactionType) -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    let onReadAloud: () -> Void
    
    @State private var showContextMenu = false
    @State private var showReactionPicker = false
    
    var body: some View {
        switch message.role {
        case .user: userBubble
        case .assistant: assistantBubble
        case .system: EmptyView()
        }
    }

    @ViewBuilder private var userBubble: some View {
        HStack {
            Spacer(minLength: 60)
            HStack(spacing: 6) {
                Text(message.content)
                    .font(.quicksandRegular(14))
                    .foregroundColor(.black)
                
                // Sent indicator
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: [.potomacYellow, .potomacYellowDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16, bottomTrailingRadius: 4, topTrailingRadius: 16))
            .shadow(color: .potomacYellow.opacity(0.2), radius: 8, y: 4)
        }
    }

    @ViewBuilder private var assistantBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            YangAvatar(size: 28, iconSize: 11)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                // Tool results
                if let tools = message.toolCalls, !tools.isEmpty {
                    ForEach(tools) { tool in
                        if tool.result != nil {
                            ToolResultView(toolCall: tool)
                                .clipped()
                        } else {
                            ToolLoadingView(toolName: tool.name, input: nil)
                        }
                    }
                }
                
                // Content
                if !message.content.isEmpty {
                    if message.isStreaming {
                        Text(message.content)
                            .font(.quicksandRegular(14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(LocalizedStringKey(message.content))
                            .font(.quicksandRegular(14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Streaming indicator
                if message.isStreaming {
                    OrganicTypingIndicator()
                }
                
                // Reaction display
                if let reaction = reaction {
                    Text(reaction.emoji)
                        .font(.system(size: 14))
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Message actions
                if !message.isStreaming && !message.content.isEmpty {
                    messageActions
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Menu {
                ForEach(MessageReactionType.allCases, id: \.self) { reactionType in
                    Button {
                        onReaction(reactionType)
                    } label: {
                        Text(reactionType.emoji)
                    }
                }
            } label: {
                Label("React", systemImage: "hand.thumbsup")
            }
            
            Button {
                onReadAloud()
            } label: {
                Label("Read Aloud", systemImage: "speaker.wave.2")
            }
        }
    }
    
    @ViewBuilder
    private var messageActions: some View {
        HStack(spacing: 12) {
            Button {
                onCopy()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                    Text("Copy")
                        .font(.quicksandSemiBold(10))
                }
                .foregroundColor(.white.opacity(0.35))
            }
            
            Button {
                showReactionPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 10))
                    Text("React")
                        .font(.quicksandSemiBold(10))
                }
                .foregroundColor(.white.opacity(0.35))
            }
            
            Button {
                onReadAloud()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 10))
                    Text("Read")
                        .font(.quicksandSemiBold(10))
                }
                .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Enhanced Typing Row

struct EnhancedTypingRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            YangAvatar(size: 28, iconSize: 11)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Yang")
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.potomacYellow.opacity(0.7))
                    
                    Text("is thinking...")
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                OrganicTypingIndicator()
            }
            .padding(.vertical, 8)
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Conversation Sidebar (Left Drawer)

struct ConversationSidebar: View {
    let viewModel: ChatViewModel
    let onDismiss: () -> Void
    @State private var searchText = ""

    private var filtered: [Conversation] {
        if searchText.isEmpty { return viewModel.conversations }
        return viewModel.conversations.filter { $0.displayTitle.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("CHATS")
                    .font(.rajdhaniBold(16))
                    .foregroundColor(.white)
                    .tracking(3)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.pressable)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 12)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.25))
                TextField("Search...", text: $searchText)
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)

            if viewModel.isLoadingConversations && viewModel.conversations.isEmpty {
                Spacer()
                ProgressView().tint(.potomacYellow)
                Spacer()
            } else if filtered.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.15))
                    Text("No chats yet")
                        .font(.quicksandRegular(13))
                        .foregroundColor(.white.opacity(0.3))
                    Button {
                        Task {
                            await viewModel.createNewConversation()
                            onDismiss()
                        }
                    } label: {
                        Text("Start a conversation")
                            .font(.quicksandSemiBold(12))
                            .foregroundColor(.potomacYellow)
                    }
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(filtered) { conv in
                            ConversationRow(
                                conversation: conv,
                                isSelected: conv.id == viewModel.currentConversation?.id
                            ) {
                                Task {
                                    await viewModel.selectConversation(conv)
                                    onDismiss()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(hex: "0D0D0D"))
        .ignoresSafeArea()
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.displayTitle)
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .lineLimit(1)
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.3))
                            .lineLimit(1)
                    } else {
                        Text(conversation.formattedDate)
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                Spacer()
                if isSelected {
                    Circle()
                        .fill(Color.potomacYellow)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.potomacYellow.opacity(0.08) : isPressed ? Color.white.opacity(0.03) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    ChatView().preferredColorScheme(.dark)
}