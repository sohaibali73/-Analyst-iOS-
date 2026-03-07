import SwiftUI
import AVFoundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Conversation Context Menu

struct ConversationContextMenu: ViewModifier {
    let conversation: Conversation
    let onRename: (String) -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    @State private var showRenameAlert = false
    @State private var renameText = ""

    func body(content: Content) -> some View {
        content
            .contextMenu {
                // Rename
                Button {
                    renameText = conversation.title
                    showRenameAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }

                // Share
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                // Delete
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
            .alert("Rename Conversation", isPresented: $showRenameAlert) {
                TextField("Conversation name", text: $renameText)
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onRename(trimmed)
                    }
                }
            } message: {
                Text("Enter a new name for this conversation.")
            }
    }
}

extension View {
    func conversationContextMenu(
        conversation: Conversation,
        onRename: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) -> some View {
        modifier(ConversationContextMenu(
            conversation: conversation,
            onRename: onRename,
            onDelete: onDelete,
            onShare: onShare
        ))
    }
}

// MARK: - Document Context Menu

struct DocumentContextMenu: ViewModifier {
    let documentTitle: String
    let onDelete: () -> Void
    let onShare: () -> Void

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

extension View {
    func documentContextMenu(
        documentTitle: String,
        onDelete: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) -> some View {
        modifier(DocumentContextMenu(
            documentTitle: documentTitle,
            onDelete: onDelete,
            onShare: onShare
        ))
    }
}

// MARK: - Message Context Menu

struct MessageContextMenu: ViewModifier {
    let message: Message
    @State private var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    func body(content: Content) -> some View {
        content
            .contextMenu {
                // Copy
                Button {
                    copyText(message.content)
                    HapticManager.shared.lightImpact()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                // Share
                if let shareURL = createShareURL(message.content) {
                    ShareLink(item: shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } else {
                    ShareLink(item: message.content) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }

                Divider()

                // Speak (TTS)
                Button {
                    toggleSpeech(message.content)
                } label: {
                    Label(
                        isSpeaking ? "Stop Speaking" : "Speak",
                        systemImage: isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill"
                    )
                }
            }
    }

    private func toggleSpeech(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        } else {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.pitchMultiplier = 1.0
            synthesizer.speak(utterance)
            isSpeaking = true
        }
    }

    private func copyText(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func createShareURL(_ text: String) -> URL? {
        nil // Return nil to use string ShareLink
    }
}

extension View {
    func messageContextMenu(message: Message) -> some View {
        modifier(MessageContextMenu(message: message))
    }
}

// MARK: - AFL Code Context Menu

struct AFLCodeContextMenu: ViewModifier {
    let code: String
    let onOptimize: () -> Void
    let onDebug: () -> Void
    let onExplain: () -> Void

    func body(content: Content) -> some View {
        content
            .contextMenu {
                // Copy
                Button {
                    copyCode(code)
                    HapticManager.shared.lightImpact()
                } label: {
                    Label("Copy Code", systemImage: "doc.on.doc")
                }

                // Share
                ShareLink(item: code) {
                    Label("Share Code", systemImage: "square.and.arrow.up")
                }

                Divider()

                // Optimize
                Button(action: onOptimize) {
                    Label("Optimize", systemImage: "bolt.fill")
                }

                // Debug
                Button(action: onDebug) {
                    Label("Debug", systemImage: "ant.fill")
                }

                // Explain
                Button(action: onExplain) {
                    Label("Explain", systemImage: "text.magnifyingglass")
                }
            }
    }

    private func copyCode(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

extension View {
    func aflCodeContextMenu(
        code: String,
        onOptimize: @escaping () -> Void,
        onDebug: @escaping () -> Void,
        onExplain: @escaping () -> Void
    ) -> some View {
        modifier(AFLCodeContextMenu(
            code: code,
            onOptimize: onOptimize,
            onDebug: onDebug,
            onExplain: onExplain
        ))
    }
}

// MARK: - Previews

#Preview("Message Context Menu") {
    VStack {
        Text("Long press me for context menu")
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .messageContextMenu(
                message: Message(
                    conversationId: "test",
                    role: .assistant,
                    content: "This is a sample message for testing context menus."
                )
            )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "0D0D0D"))
    .preferredColorScheme(.dark)
}
