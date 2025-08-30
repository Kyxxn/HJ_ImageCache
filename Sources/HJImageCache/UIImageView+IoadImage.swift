import UIKit

nonisolated(unsafe) private var imageLoadTaskKey: UInt8 = 0

extension UIImageView {
    private var imageLoadTask: Task<Void, Never>? {
        get { getAssociatedObject(self, &imageLoadTaskKey) }
        set { setAssociatedObject(self, &imageLoadTaskKey, newValue) }
    }
    
    /// 주어진 URL에서 이미지를 비동기로 로드하여 UIImageView에 설정합니다.
    /// - Parameter url: 로드할 이미지의 URL
    /// - Returns: 이미지 로딩을 수행하는 Task. URL이 nil이면 nil을 반환합니다.
    @discardableResult
    public func loadImage(
        from url: URL?,
        placeholder: UIImage? = nil,
        loader: ImageLoaderProtocol = ImageLoader.shared
    ) -> Task<Void, Never>? {
        cancelImageLoad()
        image = placeholder ?? UIImage(systemName: "photo")
        
        guard let url else {
            image = UIImage(systemName: "exclamationmark.triangle.fill")
            return nil
        }
        
        let task = Task {
            do {
                let loadedimage = try await loader.loadImage(from: url)
                try Task.checkCancellation()
                
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
                    
                    if !(error is CancellationError) {
                        HJLogger.error("이미지 로딩 실패: \(url) - \(error)")
                    }
                }
            }
        }
        
        imageLoadTask = task
        
        return task
    }
    
    private func cancelImageLoad() {
        imageLoadTask?.cancel()
        imageLoadTask = nil
    }
}
