import AppKit
import SwiftUI

@MainActor
final class WorkspacePanelController {
    private let panel: WorkspacePanel
    private let store: AppGroupStore
    private let permissions: PermissionManager
    private let viewModel: PreviewGridViewModel
    private weak var edgeLauncher: EdgeLauncherController?

    init(store: AppGroupStore) {
        self.store = store
        self.permissions = PermissionManager()
        self.viewModel = PreviewGridViewModel(store: store, permissions: permissions)
        self.panel = WorkspacePanel(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]

        let content = WorkspacePanelView(
            store: store,
            permissions: permissions,
            viewModel: viewModel,
            onClose: { [weak self] in self?.hide() }
        )
        panel.contentView = NSHostingView(rootView: content)
        panel.onEscape = { [weak self] in self?.hide() }
        panel.onShortcutNumber = { [weak self] number in
            self?.activateShortcut(number)
        }
    }

    func attachEdgeLauncher(_ edgeLauncher: EdgeLauncherController) {
        self.edgeLauncher = edgeLauncher
    }

    func show() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        edgeLauncher?.hide()
        panel.setFrame(screen.visibleFrame, display: true)
        refreshPermissions()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        viewModel.start()
    }

    func refreshPermissions() {
        permissions.refresh()
    }

    private func activateShortcut(_ number: Int) {
        guard store.entries.indices.contains(number - 1) else { return }
        let entry = store.entries[number - 1]
        hide()
        viewModel.activate(entry)
    }

    func hide() {
        viewModel.stop()
        panel.orderOut(nil)
        edgeLauncher?.show()
    }

    func terminate() {
        viewModel.stop()
        panel.close()
        edgeLauncher?.hide()
    }
}
