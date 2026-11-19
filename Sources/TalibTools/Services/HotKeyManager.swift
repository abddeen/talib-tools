import Foundation
import Carbon
import AppKit

public final class HotKeyManager {
    public static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeySignature: OSType = 0x41524243 // "ARBC"
    private let hotKeyId: UInt32 = 1001
    
    public var onHotKeyPressed: (() -> Void)?
    
    private init() {
        setupCarbonEventHandler()
    }
    
    deinit {
        unregisterHotKey()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
    
    private func setupCarbonEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handlerBlock: EventHandlerUPP = { _, event, userData in
            guard let event = event, let userData = userData else {
                return noErr
            }
            
            var hkID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkID
            )
            
            if status == noErr {
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                if hkID.signature == manager.hotKeySignature && hkID.id == manager.hotKeyId {
                    DispatchQueue.main.async {
                        manager.onHotKeyPressed?()
                    }
                }
            }
            return noErr
        }
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
    }
    
    public func register(shortcut: ShortcutModel) {
        unregisterHotKey()
        
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyId)
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        } else {
            print("Successfully registered hotkey: \(shortcut.displayString)")
        }
    }
    
    public func unregisterHotKey() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
    }
}
