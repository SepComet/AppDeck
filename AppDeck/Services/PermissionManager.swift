import ApplicationServices
import AppKit
import Combine
import CoreGraphics
import Foundation

@MainActor
final class PermissionManager: ObservableObject {
    @Published private(set) var screenRecordingGranted = false
    @Published private(set) var accessibilityGranted = false

    init() {
        refresh()
    }

    func refresh() {
        screenRecordingGranted = CGPreflightScreenCaptureAccess()
        accessibilityGranted = AXIsProcessTrusted()
    }

    func requestScreenRecordingAccess() {
        _ = CGRequestScreenCaptureAccess()
        refresh()
    }

    func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
