import UIKit

public protocol ImageLoaderProtocol {
    /// 주어진 URL에서 이미지를 비동기로 로드합니다.
    /// 캐시를 먼저 확인하고, 없는 경우에만 네트워크를 통해 데이터를 가져와 이미지로 변환합니다.
    /// - Parameter url: 이미지의 URL
    /// - Returns: 로드된 UIImage 객체
    func loadImage(from url: URL) async throws -> UIImage
}

public actor ImageLoader: ImageLoaderProtocol {
    
    // MARK: - Singleton (Type Properties/Methods)
    
    public private(set) static var shared = ImageLoader()
    
    public static func configure(
        cacheManager: ImageCacheManager = .shared,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        shared = ImageLoader(cacheManager: cacheManager, networkService: networkService)
    }
    
    // MARK: - Properties
    
    private let cacheManager: ImageCacheManager
    private let networkService: NetworkServiceProtocol
    private var activeTasks: [URL: Task<UIImage, Error>] = [:]
    
    // MARK: - Initializer
    
    public init(
        cacheManager: ImageCacheManager = .shared,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.cacheManager = cacheManager
        self.networkService = networkService
    }
    
    // MARK: - Public API
    
    public func loadImage(from url: URL) async throws -> UIImage {
        let key = url.absoluteString
        
        if let cached = await cacheManager.image(forKey: key) {
            HJLogger.info("이미지 로드 성공 (from Cache): \(key)")
            return cached
        }
        
        if let existingTask = activeTasks[url] {
            HJLogger.info("중복 요청 병합: \(key)")
            return try await existingTask.value
        }
        
        let newTask = Task<UIImage, Error> {
            defer { activeTasks[url] = nil }
            
            let data = try await networkService.request(from: url)
            
            guard let image = UIImage(data: data) else {
                throw ImageLoaderError.decodingError(URLError(.cannotDecodeContentData))
            }
            
            HJLogger.network("이미지 로드 성공 (from Network): \(key)")
            await cacheManager.setImage(image, originalData: data, forKey: key)
            
            return image
        }
        
        activeTasks[url] = newTask
        
        return try await newTask.value
    }
}
