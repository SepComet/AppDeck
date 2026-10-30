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
    case one
    case two
    case three
    case four
    case five
    case six

    // Compatibility aliases for the first persisted layout names.
    static let twoByTwo = AppLayout.four
    static let twoByThree = AppLayout.six

    var id: String { rawValue }

    var columns: Int {
        switch self {
        case .one:
            return 1
        case .two:
            return 2
        case .three, .five, .six:
            return 3
        case .four:
            return 2
        }
    }

    var rows: Int {
        switch self {
        case .one, .two, .three:
            return 1
        case .four, .five, .six:
            return 2
        }
    }

    var capacity: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        }
    }

    var title: String {
        "\(capacity) 个 · \(columns) × \(rows)"
    }

    static func forCount(_ count: Int) -> AppLayout {
        switch max(1, min(count, 6)) {
        case 1: return .one
        case 2: return .two
        case 3: return .three
        case 4: return .four
        case 5: return .five
        default: return .six
        }
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "twoByTwo": self = .four
        case "twoByThree": self = .six
        default:
            guard let layout = AppLayout(rawValue: value) else {
                throw DecodingError.dataCorruptedError(
                    in: try decoder.singleValueContainer(),
                    debugDescription: "Unknown AppLayout: \(value)"
                )
            }
            self = layout
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
