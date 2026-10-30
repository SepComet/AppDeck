import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = AppGroupStore()
    private var panelController: WorkspacePanelController!
    private var edgeLauncher: EdgeLauncherController!
    private var globalShortcut: GlobalShortcutController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        panelController = WorkspacePanelController(store: store)
        edgeLauncher = EdgeLauncherController { [weak self] in
            self?.panelController.show()
        }
        globalShortcut = GlobalShortcutController { [weak self] in
            self?.panelController.show()
        }
        panelController.attachEdgeLauncher(edgeLauncher)
        panelController.show()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController.show()
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        panelController?.refreshPermissions()
    }

    func applicationDidChangeScreenParameters(_ notification: Notification) {
        edgeLauncher?.reposition()
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelController.terminate()
    }
}
