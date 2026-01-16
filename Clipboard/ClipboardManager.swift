//
//  ClipboardManager.swift
//  Clipboard
//
//  Created by Jonathan Amobi on 15/01/2026.
//

import SwiftUI
import AppKit
import Combine

@MainActor
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []

    private let pasteboard = NSPasteboard.general
    private var changeCount = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let maxItems = 30
    private var ignoreNextChange = false
    private var pendingSave = false

    private var historyURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Clipboard", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }

    init() {
        loadHistory()
        startPolling()
    }

    func startPolling() {
        if timer != nil { return }
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(timerFired(_:)),
                                     userInfo: nil,
                                     repeats: true)
        timer?.tolerance = 0.2
    }

    @objc private func timerFired(_ timer: Timer) {
        pollClipboard()
    }

    private func pollClipboard() {
        let currentCount = pasteboard.changeCount
        if currentCount != changeCount {
            changeCount = currentCount
            checkClipboard()
        }
    }

    func checkClipboard() {
        // Skip if this change was triggered by our own copy action
        guard !ignoreNextChange else {
            ignoreNextChange = false
            return
        }

        // Prioritize images over text
        if let image = readImageFromPasteboard() {
            addImage(image)
            return
        }

        // 2. Fallback to Text
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            addText(string)
            return
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        ignoreNextChange = true
        pasteboard.clearContents()
        switch item.kind {
        case .text:
            pasteboard.setString(item.text ?? "", forType: .string)
        case .image:
            if let img = item.nsImage() {
                pasteboard.writeObjects([img])
            }
        }
        changeCount = pasteboard.changeCount
    }

    func pasteIntoFrontmostApp() {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true) // 'v'
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    func pin(_ item: ClipboardItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].pinned = true
            saveHistory()
        }
    }

    func unpin(_ item: ClipboardItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].pinned = false
            saveHistory()
        }
    }

    func remove(_ item: ClipboardItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: idx)
            saveHistory()
        }
    }

    func clear() {
        items.removeAll(where: { !$0.pinned })
        saveHistory()
    }

    // MARK: - Private
    
    private func addText(_ text: String) {
        let item = ClipboardItem(id: UUID(), kind: .text, text: text, imageData: nil, dateAdded: Date(), pinned: false)
        insertDedup(item)
    }

    private func addImage(_ image: NSImage) {
        guard let data = compressedImageData(from: image) else { return }
        let item = ClipboardItem(id: UUID(), kind: .image, text: nil, imageData: data, dateAdded: Date(), pinned: false)
        insertDedup(item)
    }

    private func insertDedup(_ item: ClipboardItem) {
        items.removeAll(where: { $0.dedupKey == item.dedupKey })
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
            ImageCache.shared.clearCache()
        }
        saveHistoryThrottled()
    }

    private func readImageFromPasteboard() -> NSImage? {
        // PNG
        if let pngData = pasteboard.data(forType: .png),
           let image = NSImage(data: pngData) {
            return image
        }
        
        // TIFF
        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData) {
            return image
        }
        
        // Image objects
        if pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes),
           let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
           let image = images.first {
            return image
        }
        
        // File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                let imageExtensions = ["png", "jpg", "jpeg", "tiff", "gif", "heic", "webp"]
                if imageExtensions.contains(url.pathExtension.lowercased()) {
                    if let image = NSImage(contentsOf: url) {
                        return image
                    }
                }
            }
        }
        
        return nil
    }

    private func compressedImageData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        // Use JPEG at 80% quality for better compression
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }

    private func saveHistoryThrottled() {
        guard !pendingSave else { return }
        pendingSave = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.pendingSave = false
            self?.saveHistory()
        }
    }
    
    private func saveHistory() {
        let itemsToSave = self.items
        let urlToSave = self.historyURL
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let data = try JSONEncoder().encode(itemsToSave)
                try data.write(to: urlToSave, options: .atomic)
            } catch {}
        }
    }

    private func loadHistory() {
        do {
            let data = try Data(contentsOf: historyURL)
            let loaded = try JSONDecoder().decode([ClipboardItem].self, from: data)
            self.items = loaded
        } catch {
            self.items = []
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}
