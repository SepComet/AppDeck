import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = AppGroupStore()
    private var panelController: WorkspacePanelController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        panelController = WorkspacePanelController(store: store)
        panelController.show()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController.show()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelController.terminate()
    }
}
