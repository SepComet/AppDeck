import AppKit
import Foundation

struct AppEntry: Codable, Equatable, Identifiable, Sendable {
    let bundleIdentifier: String
    var displayName: String
    var appPath: String
    var sortIndex: Int

    var id: String { bundleIdentifier }
}

enum AppLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case twoByTwo
    case twoByThree

    var id: String { rawValue }

    var columns: Int {
        switch self {
        case .twoByTwo:
            return 2
        case .twoByThree:
            return 3
        }
    }

    var capacity: Int {
        switch self {
        case .twoByTwo:
            return 4
        case .twoByThree:
            return 6
        }
    }

    var title: String {
        switch self {
        case .twoByTwo:
            return "2 × 2"
        case .twoByThree:
            return "2 × 3"
        }
    }
}

enum AppPreviewStatus: Equatable {
    case loading
    case ready
    case notRunning
    case unavailable
    case captureFailed
    case screenRecordingRequired
}

struct AppPreview: Identifiable {
    let entry: AppEntry
    var image: NSImage?
    var status: AppPreviewStatus

    var id: String { entry.id }
}
