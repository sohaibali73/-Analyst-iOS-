import SwiftUI

#if os(watchOS)

// MARK: - watchOS Compact Chat View

struct WatchChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var inputText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty && !viewModel.isLoadingHistory {
                    watchWelcome
                } else {
                    watchMessagesList
                }
                
                watchInputBar
            }
            .navigationTitle("Yang")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.currentConversation == nil {
                    await viewModel.loadOrCreateConversation()
                }
            }
        }
    }
    
    // MARK: - Welcome
    
    @ViewBuilder
    private var watchWelcome: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundColor(.potomacYellow)
                    .padding(.top, 8)
                
                Text("Ask Yang")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(["Market outlook?", "AAPL price?"], id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        sendMessage()
                    } label: {
                        Text(prompt)
                            .font(.caption)
                            .foregroundColor(.potomacYellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.potomacYellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Messages
    
    @ViewBuilder
    private var watchMessagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.messages) { message in
                        WatchMessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isStreaming {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Thinking...")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .id("streaming")
                    }
                    
                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Input
    
    @ViewBuilder
    private var watchInputBar: some View {
        HStack(spacing: 4) {
            TextField("Ask...", text: $inputText)
                .font(.caption)
                .textFieldStyle(.plain)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(inputText.isEmpty ? .gray : .potomacYellow)
            }
            .disabled(inputText.isEmpty || viewModel.isStreaming)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await viewModel.sendMessage(text) }
    }
}

// MARK: - Watch Message Bubble

struct WatchMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 20) }
            
            Text(message.content)
                .font(.caption2)
                .foregroundColor(message.role == .user ? .black : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    message.role == .user
                        ? Color.potomacYellow
                        : Color.white.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .lineLimit(message.isStreaming ? nil : 10)
            
            if message.role == .assistant { Spacer(minLength: 20) }
        }
    }
}

// MARK: - watchOS Main Tab View

struct WatchMainView: View {
    var body: some View {
        TabView {
            WatchChatView()
            
            WatchSettingsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

// MARK: - watchOS Settings

struct WatchSettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                Label("Profile", systemImage: "person.circle")
                    .foregroundColor(.white)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#endif
