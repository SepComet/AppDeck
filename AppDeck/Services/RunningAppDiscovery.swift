import AppKit
import Foundation

struct RunningAppCandidate: Identifiable, Equatable, Sendable {
    let bundleIdentifier: String
    let displayName: String
    let appPath: String
    let isActive: Bool

    var id: String { bundleIdentifier }
}

struct RunningAppDiscovery {
    func application(for bundleIdentifier: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == bundleIdentifier
        }
    }

    func candidates() -> [RunningAppCandidate] {
        let ownBundleIdentifier = Bundle.main.bundleIdentifier
        var seen: Set<String> = []

        return NSWorkspace.shared.runningApplications.compactMap { application in
            guard let bundleIdentifier = application.bundleIdentifier,
                  bundleIdentifier != ownBundleIdentifier,
                  seen.insert(bundleIdentifier).inserted,
                  application.activationPolicy == .regular || application.activationPolicy == .accessory,
                  let bundleURL = application.bundleURL,
                  bundleURL.pathExtension == "app" else {
                return nil
            }

            let displayName = application.localizedName
                ?? bundleURL.deletingPathExtension().lastPathComponent
            return RunningAppCandidate(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName,
                appPath: bundleURL.path,
                isActive: application.isActive
            )
        }
        .sorted { lhs, rhs in
            if lhs.isActive != rhs.isActive {
                return lhs.isActive && !rhs.isActive
            }
            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
    }
}
