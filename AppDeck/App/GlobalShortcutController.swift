import AppKit
import Carbon.HIToolbox

final class GlobalShortcutController {
    private let onTrigger: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        register()
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func register() {
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x4150444B),
            id: 1
        )
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            NSLog("AppDeck could not register Option-Space shortcut: %d", registerStatus)
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
        guard handlerStatus == noErr else {
            NSLog("AppDeck could not install Option-Space handler: %d", handlerStatus)
            if let hotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
                self.hotKeyRef = nil
            }
            return
        }
    }

    private func trigger() {
        DispatchQueue.main.async { [onTrigger] in
            onTrigger()
        }
    }

    private static let eventHandler: EventHandlerUPP = { _, _, userData in
        guard let userData else { return noErr }
        let controller = Unmanaged<GlobalShortcutController>
            .fromOpaque(userData)
            .takeUnretainedValue()
        controller.trigger()
        return noErr
    }
}
