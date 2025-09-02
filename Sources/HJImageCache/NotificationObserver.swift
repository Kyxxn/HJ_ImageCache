import UIKit

final class NotificationObserver: NSObject {
    private weak var cacheManager: ImageCacheManager?

    override init() {
        super.init()
        
        configureNotificationObserver()
    }
    
    private func configureNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc
    private func handleMemoryWarning() {
        guard let manager = self.cacheManager else { return }
        
        Task {
            HJLogger.info("메모리 경고 수신 - 메모리 캐시 정리를 시도합니다.")
            await manager.clearMemoryCache()
        }
    }
    
    func setCacheManager(_ manager: ImageCacheManager) {
        self.cacheManager = manager
    }
}
