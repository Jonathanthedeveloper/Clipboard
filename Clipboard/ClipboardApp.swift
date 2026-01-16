//
//  ClipboardApp.swift
//  Clipboard
//
//  Created by Jonathan Amobi on 15/01/2026.
//

import SwiftUI
import Cocoa

@main
struct ClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Clipboard", systemImage: "paperclip") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let hotkeyManager = GlobalHotkeyManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.start(
            keyCode: 9,
            modifiers: [.maskCommand, .maskShift]
        ) { [weak self] in
            self?.toggleMenuBarExtra()
        }
    }
    
    func toggleMenuBarExtra() {
        for window in NSApp.windows {
            let className = String(describing: type(of: window))
            
            if className.contains("NSStatusBarWindow") ||
               className.contains("MenuBarExtra") ||
               (window is NSPanel && window.level.rawValue > NSWindow.Level.normal.rawValue) {
                
                if window.isVisible {
                    window.orderOut(nil)
                } else {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
                return
            }
        }
    }
}


