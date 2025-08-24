import Foundation

public struct ImageCacheConfig: Sendable {
    /// 메모리 캐시가 사용할 최대 메모리 양(바이트 단위).
    /// 기본값은 기기 전체 RAM의 25%입니다.
    public var memoryCacheCostLimit: Int
    
    /// 메모리 캐시에 저장할 최대 아이템 개수.
    /// 기본값은 150개입니다.
    public var memoryCacheCountLimit: Int
    
    /// 디스크 캐시의 최대 저장 용량(바이트 단위).
    /// 기본값은 500MB입니다.
    public var maxDiskCacheSize: UInt
    
    /// 디스크 캐시 아이템의 최대 유효 기간(초 단위).
    /// 기본값은 7일입니다.
    public var maxDiskCacheAge: TimeInterval

    public static func `default`() -> ImageCacheConfig {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let cacheLimit = totalMemory > 0 ? Int(totalMemory / 4) : 256 * 1024 * 1024
        
        return ImageCacheConfig(
            memoryCacheCostLimit: cacheLimit,
            memoryCacheCountLimit: 150,
            maxDiskCacheSize: 1000 * 1024 * 1024,
            maxDiskCacheAge: 60 * 60 * 24 * 7
        )
    }
}
