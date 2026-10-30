import ApplicationServices
import AppKit
import Foundation
import ScreenCaptureKit

@MainActor
final class WindowActivationService {
    private let runningApps = RunningAppDiscovery()

    func activate(entry: AppEntry, previewWindow: SCWindow?, accessibilityGranted: Bool) {
        guard let application = runningApps.application(for: entry.bundleIdentifier) else {
            if let url = URL(string: "file://\(entry.appPath)") {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            }
            return
        }

        _ = application.activate(options: [.activateAllWindows])

        guard accessibilityGranted else { return }
        raiseWindow(for: application.processIdentifier, matching: previewWindow?.frame)
    }

    private func raiseWindow(for processIdentifier: pid_t, matching previewFrame: CGRect?) {
        let applicationElement = AXUIElementCreateApplication(processIdentifier)

        if let previewFrame,
           let matchedWindow = matchingWindow(in: applicationElement, previewFrame: previewFrame) {
            _ = AXUIElementPerformAction(matchedWindow, kAXRaiseAction as CFString)
            return
        }

        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            applicationElement,
            kAXMainWindowAttribute as CFString,
            &value
        )
        guard result == .success, let value else { return }

        let windowElement = unsafeBitCast(value, to: AXUIElement.self)
        _ = AXUIElementPerformAction(windowElement, kAXRaiseAction as CFString)
    }

    private func matchingWindow(
        in applicationElement: AXUIElement,
        previewFrame: CGRect
    ) -> AXUIElement? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            applicationElement,
            kAXWindowsAttribute as CFString,
            &value
        )
        guard result == .success,
              let value,
              let windows = value as? [AXUIElement] else {
            return nil
        }

        let expectedFrame = accessibilityFrame(for: previewFrame)
        return windows.first { window in
            guard let frame = accessibilityFrame(of: window) else { return false }
            let sizeMatches = abs(frame.width - expectedFrame.width) < 4
                && abs(frame.height - expectedFrame.height) < 4
            let positionMatches = abs(frame.minX - expectedFrame.minX) < 16
                && abs(frame.minY - expectedFrame.minY) < 16
            return sizeMatches && positionMatches
        }
    }

    private func accessibilityFrame(for screenCaptureFrame: CGRect) -> CGRect {
        let screenHeight = (NSScreen.main ?? NSScreen.screens.first)?.frame.maxY ?? 0
        return CGRect(
            x: screenCaptureFrame.minX,
            y: screenHeight - screenCaptureFrame.maxY,
            width: screenCaptureFrame.width,
            height: screenCaptureFrame.height
        )
    }

    private func accessibilityFrame(of window: AXUIElement) -> CGRect? {
        guard let position = accessibilityPoint(window, attribute: kAXPositionAttribute as CFString),
              let size = accessibilitySize(window, attribute: kAXSizeAttribute as CFString) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private func accessibilityPoint(_ element: AXUIElement, attribute: CFString) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgPoint else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(axValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func accessibilitySize(_ element: AXUIElement, attribute: CFString) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value else { return nil }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == .cgSize else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else { return nil }
        return size
    }
}
