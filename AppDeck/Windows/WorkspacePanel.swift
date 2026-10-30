import AppKit

final class WorkspacePanel: NSPanel {
    var onEscape: (() -> Void)?
    var onShortcutNumber: ((Int) -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
           let characters = event.charactersIgnoringModifiers,
           let number = Int(characters),
           (1...6).contains(number) {
            onShortcutNumber?(number)
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}
