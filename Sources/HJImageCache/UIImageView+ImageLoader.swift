import UIKit

extension UIImageView {
    /// URL로부터 이미지를 비동기적으로 로드하고, 진행 중인 작업을 나타내는 Task를 반환합니다.
    /// - Parameter url: 로드할 이미지의 URL
    /// - Returns: 이미지 로딩을 수행하는 Task. URL이 nil이면 nil을 반환합니다.
    @discardableResult
    public func loadImage(from url: URL?) -> Task<Void, Never>? {
        image = UIImage(systemName: "photo")
        
        guard let url = url else {
            image = UIImage(systemName: "exclamationmark.triangle.fill")
            return nil
        }
        
        let task = Task {
            do {
                let loadedimage = try await ImageLoader.shared.loadImage(from: url)
                
                if !Task.isCancelled {
                    await MainActor.run {
                        image = loadedimage
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        image = UIImage(systemName: "exclamationmark.triangle.fill")
                    }
                    HJLogger.error("이미지 로딩 실패: \(url) - \(error)")
                }
            }
        }
        
        return task
    }
}
