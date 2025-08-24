import UIKit
import CryptoKit

public actor ImageCacheManager {
    public static let shared = ImageCacheManager()
    
    // MARK: - Properties
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // MARK: - Initializer
    
    private init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ImageCache")
        
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            HJLogger.error("ImageCache 디렉토리 생성 실패: \(error)")
        }
        
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let cacheLimit = totalMemory / 4
        memoryCache.totalCostLimit = Int(cacheLimit)
    }
    
    // MARK: - Caching Methods
    
    public func setImage(_ image: UIImage, originalData: Data, forKey key: String) {
        let cost = image.cgImage.flatMap { $0.bytesPerRow * $0.height } ?? 0
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        let fileURL = cacheFileURL(forKey: key)
        
        Task.detached {
            do {
                try originalData.write(to: fileURL)
            } catch {
                HJLogger.error("ImageCache 디스크 쓰기 실패: \(error)")
            }
        }
    }
    
    public func image(forKey key: String) -> UIImage? {
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        let fileURL = cacheFileURL(forKey: key)
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else {
            return nil
        }
        
        let cost = image.cgImage.flatMap { $0.bytesPerRow * $0.height } ?? 0
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        return image
    }
    
    public func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    public func clearDiskCache() {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )
            
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            HJLogger.info("전체 디스크 캐시 삭제 완료")
        } catch {
            HJLogger.error("전체 디스크 캐시 삭제 실패: \(error)")
        }
    }
    
    public func removeImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        
        let fileURL = cacheFileURL(forKey: key)
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            HJLogger.error("디스크 캐시 삭제 실패: \(error)")
        }
    }
    
    // MARK: - Helper
    
    private func cacheFileURL(forKey key: String) -> URL {
        let fileName = cacheKey(for: key)
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    private func cacheKey(for urlString: String) -> String {
        guard let data = urlString.data(using: .utf8) else {
            return urlString.components(separatedBy: "/").last ?? urlString
        }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
