import AppKit
import Foundation

struct RunningAppDiscovery {
    func application(for bundleIdentifier: String) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == bundleIdentifier
        }
    }
}
