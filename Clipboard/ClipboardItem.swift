//
//  ClipboardItem.swift
//  Clipboard
//
//  Created by Jonathan Amobi on 15/01/2026.
//

import Foundation
import AppKit

enum ClipboardItemKind: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: ClipboardItemKind
    var text: String?
    var imageData: Data?
    var dateAdded: Date
    var pinned: Bool
    let dedupKey: String

    var displayTitle: String {
        switch kind {
        case .text:
            return text ?? ""
        case .image:
            return "Image"
        }
    }
    
    init(id: UUID, kind: ClipboardItemKind, text: String?, imageData: Data?, dateAdded: Date, pinned: Bool) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageData = imageData
        self.dateAdded = dateAdded
        self.pinned = pinned
        self.dedupKey = Self.computeDedupKey(kind: kind, text: text, imageData: imageData, id: id)
    }

    func nsImage() -> NSImage? {
        return ImageCache.shared.image(for: id, data: imageData)
    }
    
    func thumbnail() -> NSImage? {
        return ImageCache.shared.thumbnail(for: id, data: imageData)
    }

    private static func computeDedupKey(kind: ClipboardItemKind, text: String?, imageData: Data?, id: UUID) -> String {
        switch kind {
        case .text:
            return text ?? ""
        case .image:
            guard let data = imageData else { return id.uuidString }
            let size = data.count
            let prefix = data.prefix(16).map { String(format: "%02x", $0) }.joined()
            return "\(size)-\(prefix)"
        }
    }
}


