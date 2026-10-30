import Foundation
import ScreenCaptureKit

@MainActor
final class WindowDiscovery {
    func representativeWindows(for entries: [AppEntry]) async throws -> [String: SCWindow] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        let requestedIDs = Set(entries.map(\.bundleIdentifier))
        var candidates: [String: [SCWindow]] = [:]

        for window in content.windows {
            guard let application = window.owningApplication,
                  requestedIDs.contains(application.bundleIdentifier),
                  application.bundleIdentifier != Bundle.main.bundleIdentifier,
                  window.isOnScreen,
                  window.frame.width >= 160,
                  window.frame.height >= 100 else {
                continue
            }
            candidates[application.bundleIdentifier, default: []].append(window)
        }

        let normalWindows = candidates.mapValues { windows in
            let normalLayerWindows = windows.filter { $0.windowLayer == 0 }
            return normalLayerWindows.isEmpty ? windows : normalLayerWindows
        }

        return normalWindows.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value.max {
                ($0.frame.width * $0.frame.height) < ($1.frame.width * $1.frame.height)
            }
        }
    }
}
