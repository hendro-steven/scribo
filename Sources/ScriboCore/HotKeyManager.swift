import AppKit
import Carbon.HIToolbox

/// Registers system-wide hot keys via the Carbon Hot Key API. This route does
/// NOT require Accessibility/Input-Monitoring permission (unlike CGEventTap),
/// so Scribo's shortcuts work the moment it launches.
final class HotKeyManager {
    private var handlers: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    private var nextID: UInt32 = 1

    init() { installHandler() }

    private func installHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData -> OSStatus in
            guard let userData, let event else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            manager.handlers[hkID.id]?()
            return noErr
        }, 1, &spec, selfPtr, &eventHandler)
    }

    /// `keyCode` is a kVK_* virtual key; `modifiers` is a Carbon mask
    /// (shiftKey, cmdKey, optionKey, controlKey).
    @discardableResult
    func register(keyCode: Int, modifiers: Int = 0, handler: @escaping () -> Void) -> Bool {
        let id = nextID; nextID += 1
        handlers[id] = handler
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: fourCharCode("SCRB"), id: id)
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hkID,
                                         GetApplicationEventTarget(), 0, &ref)
        refs.append(ref)
        return status == noErr
    }

    private func fourCharCode(_ s: String) -> OSType {
        var result: OSType = 0
        for ch in s.utf8.prefix(4) { result = (result << 8) + OSType(ch) }
        return result
    }
}
