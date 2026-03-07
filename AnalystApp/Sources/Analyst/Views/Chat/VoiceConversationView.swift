import SwiftUI

#if os(iOS) || os(visionOS)

/// Full-screen voice conversation interface for hands-free chatting
struct VoiceConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var voiceManager = VoiceModeManager.shared
    @Environment(ChatViewModel.self) private var chatVM
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var outerPulse: CGFloat = 1.0
    @State private var conversationHistory: [VoiceMessage] = []
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isWaitingForResponse: Bool = false
    @State private var glowOpacity: Double = 0.3
    @State private var ringRotation: Double = 0
    
    private let bgColor = Color(hex: "080808")
    
    var body: some View {
        ZStack {
            // Deep dark background
            bgColor.ignoresSafeArea()
            
            // Ambient glow behind mic button
            ambientGlow
            
            VStack(spacing: 0) {
                // Header
                headerBar
                
                // Conversation area
                conversationArea
                
                Spacer(minLength: 0)
                
                // Live transcript
                if !voiceManager.currentTranscript.isEmpty && voiceManager.isListening {
                    liveTranscript
                        .padding(.bottom, 16)
                }
                
                // Central mic button
                micButton
                    .padding(.bottom, 20)
                
                // Control row
                controlRow
                    .padding(.bottom, 12)
                
                // Status
                statusIndicator
                    .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            voiceManager.isVoiceModeEnabled = true
            voiceManager.voiceModeState = .idle
            startAmbientAnimation()
        }
        .onChange(of: chatVM.isStreaming) { _, streaming in
            if !streaming && isWaitingForResponse {
                isWaitingForResponse = false
                handleAIResponse()
            }
        }
        .onDisappear {
            voiceManager.stopVoiceMode()
        }
        .alert("Voice Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Ambient Glow
    
    @ViewBuilder
    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        glowColor.opacity(glowOpacity),
                        glowColor.opacity(glowOpacity * 0.4),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 220
                )
            )
            .frame(width: 440, height: 440)
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.62)
            .blur(radius: 60)
            .animation(.easeInOut(duration: 1.5), value: voiceManager.voiceModeState)
    }
    
    private var glowColor: Color {
        switch voiceManager.voiceModeState {
        case .idle: return .potomacYellow
        case .listening: return .potomacYellow
        case .processing: return .potomacTurquoise
        case .speaking: return .potomacTurquoise
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("YANG")
                    .font(.custom("Rajdhani-Bold", size: 14))
                    .foregroundColor(.white)
                    .tracking(4)
                
                Text("Voice Mode")
                    .font(.custom("Quicksand-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.35))
            }
            
            Spacer()
            
            Button {
                // Settings
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Conversation Area
    
    @ViewBuilder
    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                if conversationHistory.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(conversationHistory) { message in
                            VoiceMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if voiceManager.voiceModeState == .processing {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .tint(.potomacTurquoise)
                                    .scaleEffect(0.8)
                                Text("Yang is thinking...")
                                    .font(.custom("Quicksand-Regular", size: 13))
                                    .foregroundColor(.potomacTurquoise.opacity(0.8))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .onChange(of: conversationHistory.count) { _, _ in
                if let last = conversationHistory.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            
            Image(systemName: "waveform.circle")
                .font(.system(size: 44, weight: .thin))
                .foregroundColor(.potomacYellow.opacity(0.25))
            
            Text("Tap the mic and\nstart speaking")
                .font(.custom("Quicksand-Regular", size: 16))
                .foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
        }
    }
    
    // MARK: - Live Transcript
    
    @ViewBuilder
    private var liveTranscript: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.potomacYellow)
                .frame(width: 6, height: 6)
                .opacity(pulseScale > 1.1 ? 1 : 0.5)
            
            Text(voiceManager.currentTranscript)
                .font(.custom("Quicksand-Regular", size: 15))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.potomacYellow.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    // MARK: - Mic Button
    
    @ViewBuilder
    private var micButton: some View {
        ZStack {
            // Outermost decorative ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            ringColor.opacity(0.0),
                            ringColor.opacity(0.3),
                            ringColor.opacity(0.0)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(ringRotation))
                .opacity(voiceManager.voiceModeState != .idle ? 1 : 0.3)
            
            // Pulse ring 1
            if voiceManager.isListening {
                Circle()
                    .stroke(Color.potomacYellow.opacity(0.25), lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - Double(pulseScale))
            }
            
            // Pulse ring 2
            if voiceManager.isSpeaking {
                Circle()
                    .stroke(Color.potomacTurquoise.opacity(0.25), lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .scaleEffect(outerPulse)
                    .opacity(2.0 - Double(outerPulse))
            }
            
            // Main button
            Circle()
                .fill(
                    LinearGradient(
                        colors: buttonColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .shadow(color: buttonShadowColor, radius: 30, y: 4)
                .scaleEffect(voiceManager.isListening || voiceManager.isSpeaking ? 1.06 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: voiceManager.voiceModeState)
            
            // Inner icon
            Image(systemName: buttonIcon)
                .font(.system(size: 38, weight: .medium))
                .foregroundColor(buttonIconColor)
                .symbolEffect(.pulse, isActive: voiceManager.voiceModeState == .processing)
        }
        .onTapGesture {
            handleMainButtonTap()
        }
        .onChange(of: voiceManager.isListening) { _, listening in
            if listening {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.4
                }
            } else {
                withAnimation(.spring(response: 0.3)) {
                    pulseScale = 1.0
                }
            }
        }
        .onChange(of: voiceManager.isSpeaking) { _, speaking in
            if speaking {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    outerPulse = 1.35
                }
            } else {
                withAnimation(.spring(response: 0.3)) {
                    outerPulse = 1.0
                }
            }
        }
    }
    
    private var ringColor: Color {
        switch voiceManager.voiceModeState {
        case .idle: return .white
        case .listening: return .potomacYellow
        case .processing: return .potomacTurquoise
        case .speaking: return .potomacTurquoise
        }
    }
    
    private var buttonColors: [Color] {
        switch voiceManager.voiceModeState {
        case .idle:
            return [Color.white.opacity(0.08), Color.white.opacity(0.04)]
        case .listening:
            return [Color.potomacYellow, Color.potomacYellow.opacity(0.85)]
        case .processing:
            return [Color.potomacTurquoise.opacity(0.3), Color.potomacTurquoise.opacity(0.15)]
        case .speaking:
            return [Color.potomacTurquoise, Color.potomacTurquoise.opacity(0.8)]
        }
    }
    
    private var buttonShadowColor: Color {
        switch voiceManager.voiceModeState {
        case .idle: return .clear
        case .listening: return .potomacYellow.opacity(0.35)
        case .processing: return .potomacTurquoise.opacity(0.2)
        case .speaking: return .potomacTurquoise.opacity(0.35)
        }
    }
    
    private var buttonIcon: String {
        switch voiceManager.voiceModeState {
        case .idle: return "mic.fill"
        case .listening: return "mic.fill"
        case .processing: return "brain.head.profile"
        case .speaking: return "speaker.wave.2.fill"
        }
    }
    
    private var buttonIconColor: Color {
        switch voiceManager.voiceModeState {
        case .idle: return .white.opacity(0.5)
        case .listening: return .black
        case .processing: return .potomacTurquoise
        case .speaking: return .black
        }
    }
    
    // MARK: - Control Row
    
    @ViewBuilder
    private var controlRow: some View {
        HStack(spacing: 0) {
            // Cancel
            controlButton(
                icon: "xmark",
                label: "Cancel",
                color: .white.opacity(0.35),
                isActive: false
            ) {
                cancelCurrentAction()
            }
            .opacity(voiceManager.voiceModeState == .idle ? 0.3 : 1.0)
            .disabled(voiceManager.voiceModeState == .idle)
            
            Spacer()
            
            // Auto / Manual toggle
            controlButton(
                icon: voiceManager.autoDetectSilence ? "waveform.badge.mic" : "hand.tap",
                label: voiceManager.autoDetectSilence ? "Auto" : "Manual",
                color: voiceManager.autoDetectSilence ? .potomacYellow : .white.opacity(0.35),
                isActive: voiceManager.autoDetectSilence
            ) {
                voiceManager.autoDetectSilence.toggle()
                HapticManager.shared.selection()
            }
            
            Spacer()
            
            // Speak toggle
            controlButton(
                icon: voiceManager.speakResponses ? "speaker.wave.2.fill" : "speaker.slash.fill",
                label: voiceManager.speakResponses ? "Voice On" : "Voice Off",
                color: voiceManager.speakResponses ? .potomacTurquoise : .white.opacity(0.35),
                isActive: voiceManager.speakResponses
            ) {
                voiceManager.speakResponses.toggle()
                HapticManager.shared.selection()
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private func controlButton(icon: String, label: String, color: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(isActive ? 0.12 : 0.04))
                    )
                
                Text(label)
                    .font(.custom("Quicksand-Medium", size: 10))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Status
    
    @ViewBuilder
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(voiceManager.voiceModeState.statusText)
                .font(.custom("Quicksand-Medium", size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }
    
    private var statusColor: Color {
        switch voiceManager.voiceModeState {
        case .idle: return .white.opacity(0.2)
        case .listening: return .potomacYellow
        case .processing: return .potomacTurquoise
        case .speaking: return .green
        }
    }
    
    // MARK: - Actions
    
    private func startAmbientAnimation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.15
        }
    }
    
    private func handleMainButtonTap() {
        switch voiceManager.voiceModeState {
        case .idle:
            Task {
                let success = await voiceManager.startListening()
                if !success {
                    errorMessage = "Unable to start voice recognition. Please check microphone and speech recognition permissions in Settings."
                    showError = true
                }
            }
        case .listening:
            processTranscript()
        case .processing:
            chatVM.stopStreaming()
            isWaitingForResponse = false
            voiceManager.voiceModeState = .idle
        case .speaking:
            voiceManager.stopSpeaking()
        }
        HapticManager.shared.mediumImpact()
    }
    
    private func processTranscript() {
        let text = voiceManager.currentTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            voiceManager.voiceModeState = .idle
            return
        }
        
        conversationHistory.append(VoiceMessage(content: text, isUser: true))
        voiceManager.currentTranscript = ""
        voiceManager.voiceModeState = .processing
        isWaitingForResponse = true
        
        Task {
            await chatVM.sendMessage(text)
        }
    }
    
    private func handleAIResponse() {
        if let lastMessage = chatVM.messages.last, lastMessage.role == .assistant, !lastMessage.content.isEmpty {
            conversationHistory.append(VoiceMessage(content: lastMessage.content, isUser: false))
            
            if voiceManager.speakResponses {
                voiceManager.speak(lastMessage.content)
            } else {
                voiceManager.voiceModeState = .idle
            }
        } else {
            voiceManager.voiceModeState = .idle
        }
    }
    
    private func cancelCurrentAction() {
        if voiceManager.isListening { voiceManager.stopListening() }
        if voiceManager.isSpeaking { voiceManager.stopSpeaking() }
        chatVM.stopStreaming()
        voiceManager.voiceModeState = .idle
        voiceManager.currentTranscript = ""
        isWaitingForResponse = false
        HapticManager.shared.lightImpact()
    }
}

// MARK: - Voice Message Model

struct VoiceMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    
    static func == (lhs: VoiceMessage, rhs: VoiceMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Voice Message Bubble

struct VoiceMessageBubble: View {
    let message: VoiceMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.custom("Quicksand-Regular", size: 15))
                    .foregroundColor(message.isUser ? .black : .white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                            ? Color.potomacYellow
                            : Color.white.opacity(0.06)
                    )
                    .clipShape(
                        message.isUser
                            ? UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 6, topTrailingRadius: 18)
                            : UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 18)
                    )
                    .overlay(
                        Group {
                            if !message.isUser {
                                (message.isUser
                                    ? UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 6, topTrailingRadius: 18)
                                    : UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 18, bottomTrailingRadius: 18, topTrailingRadius: 18)
                                )
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            }
                        }
                    )
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.custom("Quicksand-Regular", size: 10))
                    .foregroundColor(.white.opacity(0.2))
            }
            
            if !message.isUser { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceConversationView()
        .environment(ChatViewModel())
}

#endif
