import AppKit
import Foundation
import ScreenCaptureKit

enum WindowCaptureError: LocalizedError {
    case emptyImage

    var errorDescription: String? {
        switch self {
        case .emptyImage:
            return "系统没有返回窗口画面。"
        }
    }
}

@MainActor
final class WindowCaptureService {
    func capture(window: SCWindow, targetSize: CGSize = CGSize(width: 960, height: 600)) async throws -> NSImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.width = max(1, Int(targetSize.width))
        configuration.height = max(1, Int(targetSize.height))
        configuration.showsCursor = false

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        guard image.width > 0, image.height > 0 else {
            throw WindowCaptureError.emptyImage
        }
        return NSImage(cgImage: image, size: targetSize)
    }
}
