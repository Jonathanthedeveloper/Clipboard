import AppKit
import Foundation

final class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, NSImage>()
    private let thumbnailCache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 5
        cache.totalCostLimit = 20 * 1024 * 1024 // 20MB max
        
        thumbnailCache.countLimit = 30
        thumbnailCache.totalCostLimit = 5 * 1024 * 1024 // 5MB for thumbnails
    }
    
    func image(for id: UUID, data: Data?) -> NSImage? {
        let key = id.uuidString as NSString
        
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        guard let data = data, let image = NSImage(data: data) else {
            return nil
        }
        
        cache.setObject(image, forKey: key)
        return image
    }
    
    func thumbnail(for id: UUID, data: Data?, size: CGSize = CGSize(width: 100, height: 80)) -> NSImage? {
        let key = id.uuidString as NSString
        
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }
        
        guard let data = data, let original = NSImage(data: data) else {
            return nil
        }
        
        let thumbnail = createThumbnail(from: original, size: size)
        thumbnailCache.setObject(thumbnail, forKey: key)
        return thumbnail
    }
    
    private func createThumbnail(from image: NSImage, size: CGSize) -> NSImage {
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .low
        image.draw(in: CGRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()
        return thumbnail
    }
    
    func clearCache() {
        cache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }
}
