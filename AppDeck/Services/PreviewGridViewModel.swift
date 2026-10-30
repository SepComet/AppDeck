import AppKit
import Combine
import Foundation
import ScreenCaptureKit

@MainActor
final class PreviewGridViewModel: ObservableObject {
    @Published private(set) var previews: [String: AppPreview] = [:]

    private let store: AppGroupStore
    private let permissions: PermissionManager
    private let windowDiscovery = WindowDiscovery()
    private let captureService = WindowCaptureService()
    private let activationService = WindowActivationService()
    private var refreshTask: Task<Void, Never>?
    private var windows: [String: SCWindow] = [:]

    init(store: AppGroupStore, permissions: PermissionManager) {
        self.store = store
        self.permissions = permissions
    }

    func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await refreshOnce()
                do {
                    try await Task.sleep(for: .seconds(2))
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refreshNow() {
        Task { [weak self] in
            await self?.refreshOnce()
        }
    }

    func activate(_ entry: AppEntry) {
        stop()
        activationService.activate(
            entry: entry,
            previewWindow: windows[entry.id],
            accessibilityGranted: permissions.accessibilityGranted
        )
    }

    private func refreshOnce() async {
        let entries = store.entries
        guard !entries.isEmpty else {
            previews = [:]
            windows = [:]
            return
        }

        guard permissions.screenRecordingGranted else {
            previews = Dictionary(uniqueKeysWithValues: entries.map {
                ($0.id, AppPreview(entry: $0, image: nil, status: .screenRecordingRequired))
            })
            return
        }

        previews = Dictionary(uniqueKeysWithValues: entries.map {
            ($0.id, AppPreview(entry: $0, image: previews[$0.id]?.image, status: .loading))
        })

        do {
            windows = try await windowDiscovery.representativeWindows(for: entries)
        } catch {
            previews = Dictionary(uniqueKeysWithValues: entries.map {
                ($0.id, AppPreview(entry: $0, image: nil, status: .unavailable))
            })
            return
        }

        for entry in entries {
            guard !Task.isCancelled else { return }
            guard let window = windows[entry.id] else {
                previews[entry.id] = AppPreview(entry: entry, image: nil, status: .notRunning)
                continue
            }

            do {
                let image = try await captureService.capture(window: window)
                previews[entry.id] = AppPreview(entry: entry, image: image, status: .ready)
            } catch {
                previews[entry.id] = AppPreview(entry: entry, image: nil, status: .captureFailed)
            }
        }
    }
}
