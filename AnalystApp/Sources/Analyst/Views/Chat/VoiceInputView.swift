import SwiftUI

#if os(iOS) || os(visionOS)
import Speech
import AVFoundation

// MARK: - Voice Input View (iOS / visionOS only)

struct VoiceInputView: View {
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var permissionStatus: PermissionStatus = .unknown
    @State private var pulseScale: CGFloat = 1.0
    @State private var showPermissionAlert = false

    let onSend: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "0D0D0D").ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("VOICE INPUT")
                        .font(.custom("Rajdhani-Bold", size: 16))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button(action: {
                        stopRecordingIfNeeded()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)

                Spacer()

                // Recording indicator
                ZStack {
                    // Outer pulse rings
                    if isRecording {
                        Circle()
                            .stroke(Color.potomacYellow.opacity(0.15), lineWidth: 2)
                            .frame(width: 160, height: 160)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - Double(pulseScale))

                        Circle()
                            .stroke(Color.potomacYellow.opacity(0.1), lineWidth: 1.5)
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseScale * 0.85)
                            .opacity(2.0 - Double(pulseScale * 0.85))
                    }

                    // Inner circle
                    Circle()
                        .fill(isRecording ? Color.potomacYellow : Color.white.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .shadow(color: isRecording ? Color.potomacYellow.opacity(0.4) : .clear, radius: 20)

                    // Mic icon
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(isRecording ? .black : .white.opacity(0.5))
                }
                .onTapGesture {
                    toggleRecording()
                }
                .animation(.easeInOut(duration: 0.3), value: isRecording)

                // Status text
                Text(statusText)
                    .font(.custom("Quicksand-Regular", size: 14))
                    .foregroundColor(isRecording ? Color.potomacYellow : .white.opacity(0.35))
                    .animation(.easeInOut, value: isRecording)

                Spacer()

                // Transcribed text area
                VStack(alignment: .leading, spacing: 8) {
                    Text("TRANSCRIPTION")
                        .font(.custom("Quicksand-SemiBold", size: 10))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.5)

                    ZStack(alignment: .topLeading) {
                        if transcribedText.isEmpty {
                            Text("Tap the microphone and start speaking...")
                                .font(.custom("Quicksand-Regular", size: 14))
                                .foregroundColor(.white.opacity(0.2))
                                .padding(14)
                        }
                        TextEditor(text: $transcribedText)
                            .font(.custom("Quicksand-Regular", size: 14))
                            .foregroundColor(.white)
                            .frame(minHeight: 80, maxHeight: 140)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(10)
                    }
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)

                // Action buttons
                HStack(spacing: 12) {
                    // Clear button
                    Button {
                        transcribedText = ""
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("Clear")
                                .font(.custom("Quicksand-SemiBold", size: 14))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .disabled(transcribedText.isEmpty)

                    // Send button
                    Button {
                        stopRecordingIfNeeded()
                        let text = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        onSend(text)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                            Text("Send to Chat")
                                .font(.custom("Rajdhani-Bold", size: 16))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.potomacYellow.opacity(0.5)
                            : Color.potomacYellow
                        )
                        .cornerRadius(12)
                    }
                    .disabled(transcribedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            checkPermissions()
        }
        .onDisappear {
            stopRecordingIfNeeded()
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                startPulseAnimation()
            }
        }
        .alert("Permissions Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Microphone and Speech Recognition permissions are required for voice input. Please enable them in Settings.")
        }
    }

    // MARK: - Status Text

    private var statusText: String {
        switch permissionStatus {
        case .unknown:
            return "Checking permissions..."
        case .denied:
            return "Permissions required — tap mic to request"
        case .granted:
            return isRecording ? "Listening..." : "Tap the microphone to start"
        }
    }

    // MARK: - Permissions

    private func checkPermissions() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioApplication.shared.recordPermission

        if speechStatus == .authorized && micStatus == .granted {
            permissionStatus = .granted
        } else if speechStatus == .denied || speechStatus == .restricted || micStatus == .denied {
            permissionStatus = .denied
        } else {
            permissionStatus = .unknown
        }
    }

    private func requestPermissions() async {
        // Request speech recognition permission
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        // Request microphone permission
        let micGranted: Bool
        if #available(iOS 17, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        await MainActor.run {
            if speechGranted && micGranted {
                permissionStatus = .granted
            } else {
                permissionStatus = .denied
                showPermissionAlert = true
            }
        }
    }

    // MARK: - Recording

    private func toggleRecording() {
        if permissionStatus != .granted {
            Task { await requestPermissions() }
            return
        }

        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        speechRecognizer.startTranscribing { text in
            transcribedText = text
        }
        isRecording = true
        HapticManager.shared.mediumImpact()
    }

    private func stopRecording() {
        speechRecognizer.stopTranscribing()
        isRecording = false
        HapticManager.shared.lightImpact()
    }

    private func stopRecordingIfNeeded() {
        if isRecording {
            stopRecording()
        }
    }

    // MARK: - Pulse Animation

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
        }
    }

    // MARK: - Permission Status

    private enum PermissionStatus {
        case unknown, granted, denied
    }
}

// MARK: - Speech Recognizer

@Observable
final class SpeechRecognizer {
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }

    func startTranscribing(onResult: @escaping (String) -> Void) {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    onResult(result.bestTranscription.formattedString)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ Audio engine start failed: \(error)")
        }
    }

    func stopTranscribing() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
    }
}

// MARK: - Preview

#Preview {
    VoiceInputView(
        onSend: { text in print("Send: \(text)") },
        onDismiss: { print("Dismiss") }
    )
    .preferredColorScheme(.dark)
}

#endif
