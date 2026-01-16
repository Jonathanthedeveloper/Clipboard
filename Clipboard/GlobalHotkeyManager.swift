import Cocoa

final class GlobalHotkeyManager {
    private var eventTap: CFMachPort?
    private var handler: (() -> Void)?
    private var targetKeyCode: CGKeyCode = 0
    private var targetModifiers: CGEventFlags = []
    
    func start(keyCode: CGKeyCode, modifiers: CGEventFlags, handler: @escaping () -> Void) {
        self.handler = handler
        self.targetKeyCode = keyCode
        self.targetModifiers = modifiers
        
        let mask = (1 << CGEventType.keyDown.rawValue)
        
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { proxy, type, event, refcon in
                guard type == .keyDown else { return Unmanaged.passUnretained(event) }
                
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon!).takeUnretainedValue()
                
                let pressedKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags
                
                if pressedKeyCode == Int64(manager.targetKeyCode) &&
                   flags.contains(manager.targetModifiers) {
                    DispatchQueue.main.async {
                        manager.handler?()
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        )
        
        guard let eventTap else {
            #if DEBUG
            print("GlobalHotkeyManager: Failed to create event tap")
            #endif
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }
    
    deinit {
        stop()
    }
}
