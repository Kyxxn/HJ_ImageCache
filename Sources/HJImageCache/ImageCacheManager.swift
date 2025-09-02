import UIKit
import CryptoKit

public actor ImageCacheManager {
    
    // MARK: - Singleton
    
    public private(set) static var shared = ImageCacheManager(config: .default())
    
    public static func setup(with config: ImageCacheConfig) {
        shared = ImageCacheManager(config: config)
    }
    
    // MARK: - Properties
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let config: ImageCacheConfig
    private let notificationObserver: NotificationObserver?
    
    // MARK: - Initializer
    
    private init(config: ImageCacheConfig) {
        self.config = config
        self.cacheDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("ImageCache")
        
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            HJLogger.error("ImageCache 디렉토리 생성 실패: \(error)")
        }
        
        memoryCache.totalCostLimit = config.memoryCacheCostLimit
        memoryCache.countLimit = config.memoryCacheCountLimit
        
        let observer = NotificationObserver()
        notificationObserver = observer
        observer.setCacheManager(self)
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
    
    public func cleanExpiredDiskCache() {
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .contentModificationDateKey,
            .creationDateKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey
        ]
        
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            HJLogger.error("캐시 디렉토리의 파일 목록을 가져오는 데 실패했습니다.")
            return
        }
        
        let now = Date()
        var totalSize: UInt64 = 0
        var unexpiredFiles: [(url: URL, modificationDate: Date, fileSize: UInt64)] = []
        
        for fileURL in fileURLs {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  resourceValues.isDirectory != true else {
                continue
            }
            
            // 수정일(없으면 생성일) 추출
            let modificationDate = resourceValues.contentModificationDate
            ?? resourceValues.creationDate
            ?? Date.distantPast
            
            // 파일 크기 (totalFileAllocatedSize -> fileAllocatedSize 순으로 fallback)
            let sizeInt = resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0
            let fileSize = UInt64(max(0, sizeInt))
            
            // 만료 여부 판단
            if now.timeIntervalSince(modificationDate) > config.maxDiskCacheAge {
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch {
                    HJLogger.error("만료 파일 삭제 실패: \(fileURL.lastPathComponent) - \(error)")
                }
            } else {
                unexpiredFiles.append((url: fileURL, modificationDate: modificationDate, fileSize: fileSize))
                totalSize &+= fileSize
            }
        }
        
        let maxSize = UInt64(config.maxDiskCacheSize)
        guard totalSize > maxSize else {
            return
        }
        
        unexpiredFiles.sort { $0.modificationDate < $1.modificationDate }
        
        for entry in unexpiredFiles {
            if totalSize <= maxSize { break }
            do {
                try fileManager.removeItem(at: entry.url)
                totalSize &-= min(totalSize, entry.fileSize)
            } catch {
                HJLogger.error("용량 초과 정리 중 삭제 실패: \(entry.url.lastPathComponent) - \(error)")
            }
        }
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
    
    public func calculateDiskCacheSize() async throws -> UInt64 {
        let resourceKeys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        let fileURLs = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )
        
        var totalSize: UInt64 = 0
        for fileURL in fileURLs {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            let sizeInt = resourceValues.totalFileAllocatedSize ?? 0
            totalSize &+= UInt64(max(0, sizeInt))
        }
        
        return totalSize
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
