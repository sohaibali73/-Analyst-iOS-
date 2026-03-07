import Foundation

#if canImport(Speech) && canImport(AVFoundation) && !os(watchOS)
import Speech
import AVFoundation

/// Manages voice mode for hands-free conversation (iOS / visionOS)
@MainActor
class VoiceModeManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = VoiceModeManager()
    
    // MARK: - Published Properties
    
    @Published var isVoiceModeEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isVoiceModeEnabled, forKey: "voiceModeEnabled")
            if !isVoiceModeEnabled {
                stopVoiceMode()
            }
        }
    }
    
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var currentTranscript: String = ""
    @Published var lastAIResponse: String = ""
    @Published var voiceModeState: VoiceModeState = .idle
    
    // MARK: - Settings
    
    @Published var speechRate: Float = 0.5 {
        didSet { UserDefaults.standard.set(speechRate, forKey: "voiceSpeechRate") }
    }
    
    @Published var speechPitch: Float = 1.0 {
        didSet { UserDefaults.standard.set(speechPitch, forKey: "voiceSpeechPitch") }
    }
    
    @Published var autoDetectSilence: Bool = true {
        didSet { UserDefaults.standard.set(autoDetectSilence, forKey: "voiceAutoDetectSilence") }
    }
    
    @Published var silenceThreshold: Double = 2.0 {
        didSet { UserDefaults.standard.set(silenceThreshold, forKey: "voiceSilenceThreshold") }
    }
    
    @Published var speakResponses: Bool = true {
        didSet { UserDefaults.standard.set(speakResponses, forKey: "voiceSpeakResponses") }
    }
    
    // MARK: - Private Properties
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var synthesizer: AVSpeechSynthesizer?
    
    private var silenceTimer: Timer?
    private var lastSpeechTime: Date?
    private var accumulatedText: String = ""
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        // Load saved settings
        isVoiceModeEnabled = UserDefaults.standard.bool(forKey: "voiceModeEnabled")
        speechRate = Float(UserDefaults.standard.double(forKey: "voiceSpeechRate"))
        if speechRate == 0 { speechRate = 0.5 }
        speechPitch = Float(UserDefaults.standard.double(forKey: "voiceSpeechPitch"))
        if speechPitch == 0 { speechPitch = 1.0 }
        autoDetectSilence = UserDefaults.standard.object(forKey: "voiceAutoDetectSilence") as? Bool ?? true
        silenceThreshold = UserDefaults.standard.double(forKey: "voiceSilenceThreshold")
        if silenceThreshold == 0 { silenceThreshold = 2.0 }
        speakResponses = UserDefaults.standard.object(forKey: "voiceSpeakResponses") as? Bool ?? true
        
        // Initialize speech recognizer
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Initialize synthesizer
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
    }
    
    // MARK: - Voice Mode Control
    
    func startVoiceMode() {
        guard isVoiceModeEnabled else { return }
        voiceModeState = .idle
    }
    
    func stopVoiceMode() {
        stopListening()
        stopSpeaking()
        voiceModeState = .idle
        currentTranscript = ""
        lastAIResponse = ""
    }
    
    // MARK: - Listening
    
    func startListening() async -> Bool {
        guard await requestPermissions() else {
            return false
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            return false
        }
        
        // Configure audio session
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
            return false
        }
        #endif
        
        // Setup audio engine
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest!.shouldReportPartialResults = true
        recognitionRequest!.addsPunctuation = true
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start recognition task
        accumulatedText = ""
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognitionResult(result, error: error)
            }
        }
        
        // Start audio engine
        audioEngine?.prepare()
        do {
            try audioEngine?.start()
        } catch {
            print("❌ Audio engine start error: \(error)")
            return false
        }
        
        isListening = true
        voiceModeState = .listening
        HapticManager.shared.mediumImpact()
        
        // Start silence detection
        if autoDetectSilence {
            startSilenceDetection()
        }
        
        return true
    }
    
    func stopListening() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        isListening = false
        
        // Deactivate audio session
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        guard let result = result else {
            if let error = error {
                print("❌ Recognition error: \(error)")
            }
            return
        }
        
        currentTranscript = result.bestTranscription.formattedString
        
        // Update last speech time for silence detection
        if !currentTranscript.isEmpty {
            lastSpeechTime = Date()
        }
        
        // If final, process the text
        if result.isFinal {
            accumulatedText = currentTranscript
        }
    }
    
    // MARK: - Silence Detection
    
    private func startSilenceDetection() {
        lastSpeechTime = Date()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForSilence()
            }
        }
    }
    
    private func checkForSilence() {
        guard let lastSpeech = lastSpeechTime else { return }
        
        let elapsed = Date().timeIntervalSince(lastSpeech)
        if elapsed >= silenceThreshold && !currentTranscript.isEmpty {
            // User has stopped speaking
            finishListeningAndProcess()
        }
    }
    
    func finishListeningAndProcess() {
        guard !currentTranscript.isEmpty else { return }
        
        stopListening()
        voiceModeState = .processing
        HapticManager.shared.lightImpact()
    }
    
    // MARK: - Speaking (Text-to-Speech)
    
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Clean up text for more natural speech
        let cleanText = prepareTextForSpeech(text)
        
        let utterance = AVSpeechUtterance(string: cleanText)
        
        let naturalRate: Float = 0.45
        utterance.rate = naturalRate + (speechRate - 0.5) * 0.3
        utterance.pitchMultiplier = 0.95 + (speechPitch - 1.0) * 0.2
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
        utterance.voice = getBestAvailableVoice()
        
        // Configure audio session for high-quality playback
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session config error: \(error)")
        }
        #endif
        
        isSpeaking = true
        voiceModeState = .speaking
        lastAIResponse = text
        
        synthesizer?.speak(utterance)
    }
    
    private func prepareTextForSpeech(_ text: String) -> String {
        var cleanText = text
        
        // Remove markdown formatting
        cleanText = cleanText.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "__(.+?)__", with: "$1", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "`(.+?)`", with: "$1", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: "```[\\s\\S]*?```", with: " code block. ", options: .regularExpression)
        
        // Replace common abbreviations
        cleanText = cleanText.replacingOccurrences(of: "\\bAFL\\b", with: "A F L")
        cleanText = cleanText.replacingOccurrences(of: "\\bAPI\\b", with: "A P I")
        cleanText = cleanText.replacingOccurrences(of: "\\bURL\\b", with: "U R L")
        cleanText = cleanText.replacingOccurrences(of: "\\bETF\\b", with: "E T F")
        
        // Handle symbols
        cleanText = cleanText.replacingOccurrences(of: "%", with: " percent")
        cleanText = cleanText.replacingOccurrences(of: "&", with: " and ")
        cleanText = cleanText.replacingOccurrences(of: "$", with: " dollars ")
        
        // Clean up extra whitespace
        cleanText = cleanText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanText
    }
    
    private func getBestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let usEnglishVoices = voices.filter { $0.language == "en-US" }
        let allEnglishVoices = voices.filter { $0.language.hasPrefix("en") }
        
        if let premium = usEnglishVoices.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = usEnglishVoices.first(where: { $0.quality == .enhanced }) { return enhanced }
        if let premium = allEnglishVoices.first(where: { $0.quality == .premium }) { return premium }
        if let enhanced = allEnglishVoices.first(where: { $0.quality == .enhanced }) { return enhanced }
        
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    func stopSpeaking() {
        synthesizer?.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
    
    // MARK: - Permissions
    
    private func requestPermissions() async -> Bool {
        let speechAuth = SFSpeechRecognizer.authorizationStatus()
        if speechAuth == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            if !granted { return false }
        } else if speechAuth != .authorized {
            return false
        }
        
        #if os(iOS)
        let micAuth = AVAudioApplication.shared.recordPermission
        if micAuth == .undetermined {
            let granted = await AVAudioApplication.requestRecordPermission()
            return granted
        }
        return micAuth == .granted
        #else
        return true
        #endif
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension VoiceModeManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.voiceModeState = .idle
            HapticManager.shared.lightImpact()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.voiceModeState = .idle
        }
    }
}

#else

// MARK: - Stub for macOS / watchOS / platforms without Speech framework

@MainActor
class VoiceModeManager: NSObject, ObservableObject {
    static let shared = VoiceModeManager()
    
    @Published var isVoiceModeEnabled: Bool = false
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var currentTranscript: String = ""
    @Published var lastAIResponse: String = ""
    @Published var voiceModeState: VoiceModeState = .idle
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0
    @Published var autoDetectSilence: Bool = true
    @Published var silenceThreshold: Double = 2.0
    @Published var speakResponses: Bool = true
    
    private override init() { super.init() }
    
    func startVoiceMode() {}
    func stopVoiceMode() {}
    func startListening() async -> Bool { return false }
    func stopListening() {}
    func finishListeningAndProcess() {}
    func speak(_ text: String) {}
    func stopSpeaking() {}
}

#endif

// MARK: - Voice Mode State (Cross-Platform)

enum VoiceModeState {
    case idle
    case listening
    case processing
    case speaking
    
    var statusText: String {
        switch self {
        case .idle: return "Tap to speak"
        case .listening: return "Listening..."
        case .processing: return "Thinking..."
        case .speaking: return "Speaking..."
        }
    }
    
    var iconName: String {
        switch self {
        case .idle: return "mic"
        case .listening: return "mic.fill"
        case .processing: return "brain.head.profile"
        case .speaking: return "speaker.wave.3.fill"
        }
    }
}
