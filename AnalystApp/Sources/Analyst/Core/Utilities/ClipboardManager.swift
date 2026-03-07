import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Cross-Platform Clipboard Manager

/// Unified clipboard access across iOS, macOS, watchOS, and visionOS
enum ClipboardManager {
    /// Copy text to the system clipboard
    static func copy(_ text: String) {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        // watchOS does not have a clipboard — no-op
        print("⚠️ Clipboard not available on this platform")
        #endif
    }

    /// Read text from the system clipboard (returns nil on unsupported platforms)
    static func paste() -> String? {
        #if os(iOS) || os(visionOS)
        return UIPasteboard.general.string
        #elseif os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }

    /// Whether clipboard operations are supported on the current platform
    static var isAvailable: Bool {
        #if os(iOS) || os(visionOS) || os(macOS)
        return true
        #else
        return false
        #endif
    }
}
